class AuthController < ApplicationController
  allow_unauthenticated_access only: %i[ index new create create_email track ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to slack_login_url, alert: "Try again later." }
  skip_forgery_protection only: %i[ track ]

  layout false

  before_action :set_after_login_redirect, only: %i[ index new create_email ]
  before_action :redirect_if_logged_in, only: %i[ index new create create_email ]

  def index
    render "auth/index", layout: false
  end

  # Slack auth start
  def new
    if user_logged_in?
      redirect_to(post_login_redirect_path || home_path)
      return
    end

    ahoy.track "slack_login_start"

    state = SecureRandom.hex(24)
    session[:state] = state

    params = {
      client_id: ENV.fetch("SLACK_CLIENT_ID", nil),
      redirect_uri: slack_callback_url,
      state: state,
      user_scope: "identity.basic,identity.email,identity.team,identity.avatar",
      team: "T0266FRGM"
    }
    redirect_to "https://slack.com/oauth/v2/authorize?#{params.to_query}", allow_other_host: true
  end

  # email login
  def create_email
    email = params[:email]
    otp = params[:otp]

    if email.blank? || !(email =~ URI::MailTo::EMAIL_REGEXP)
      flash.now[:alert] = "Invalid email address."
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "flash",
              partial: "shared/notice"
            )
          ]
        end
      end
      return
    end

    if otp.present?
      unless AllowedEmail.allowed?(email)
        flash.now[:alert] = "You do not have access."
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                "flash",
                partial: "shared/notice"
              )
            ]
          end
        end
        return
      end

      if validate_otp(email, otp)
        referrer_id = cookies[:referrer_id]&.to_i
        user = User.find_or_create_from_email(email, referrer_id: referrer_id)
        ahoy.track("email_login", user_id: user&.id)
        reset_session
        session[:user_id] = user.id

        # Clear the referrer cookie after successful signup
        cookies.delete(:referrer_id) if referrer_id

        Rails.logger.info("OTP validated for email: #{email}")
        redirect_target = post_login_redirect_path
        redirect_to(redirect_target || home_path)
      else
        flash.now[:alert] = "Invalid OTP. Please try again."
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                "flash",
                partial: "shared/notice"
              )
            ]
          end
        end
      end
      return
    end

    unless AllowedEmail.allowed?(email)
      flash.now[:alert] = "You do not have access."
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "flash",
              partial: "shared/notice",
            ),
            turbo_stream.replace(
              "login_form",
              partial: "auth/email_form"
            )
          ]
        end
      end
      return
    end

    if send_otp(email)
      ahoy.track "email_login_start"

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "login_form",
            partial: "auth/otp_form",
            locals: { email: email }
          )
        end
      end
    else
      flash.now[:alert] = "Failed to send OTP. Please try again."
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "flash",
              partial: "shared/notice",
            ),
            turbo_stream.replace(
              "login_form",
              partial: "auth/email_form"
            )
          ]
        end
      end
    end
  end

  # Slack auth callback
  def create
    if params[:state] != session[:state]
      Rails.logger.tagged("Authentication") do
        Rails.logger.error({
          event: "csrf_validation_failed",
          expected_state: session[:state],
          received_state: params[:state]
        }.to_json)
      end
      session[:state] = nil
      redirect_to login_path, alert: "Authentication failed due to CSRF token mismatch"
      return
    end

    begin
      referrer_id = cookies[:referrer_id]&.to_i
      user = User.exchange_slack_token(params[:code], slack_callback_url, referrer_id: referrer_id)
      user.refresh_profile! if user
      ahoy.track("slack_login", user_id: user&.id)
      reset_session
      session[:user_id] = user.id

      # Clear the referrer cookie after successful signup
      cookies.delete(:referrer_id) if referrer_id

      Rails.logger.tagged("Authentication") do
        Rails.logger.info({
          event: "authentication_successful",
          user_id: user.id,
          slack_id: user.slack_id
        }.to_json)
      end

      redirect_to(post_login_redirect_path || home_path, notice: "Welcome, #{user.display_name}!")
    rescue StandardError => e
      Rails.logger.tagged("Authentication") do
        Rails.logger.error({
          event: "authentication_failed",
          error: e.message
        }.to_json)
      end
      redirect_to login_path, alert: e.message
    end
  end

  # GitHub auth start
  def github
    state = SecureRandom.hex(16)
    session[:github_state] = state
    redirect_to "https://github.com/apps/blueprint-hackclub/installations/new?state=#{state}", allow_other_host: true
  end

  # GitHub auth callback
  def create_github
    begin
      if !user_logged_in?
        redirect_to root_path, alert: "You must be logged in to link your GitHub account."
        return
      end

      if session[:github_state].blank? || session[:github_state] != params[:state]
        redirect_to home_path, alert: "Invalid GitHub linking session. Please try again."
        return
      end

      session.delete(:github_state) if Rails.env.production?
      current_user.link_github_account(params[:installation_id])

      Rails.logger.tagged("Authentication") do
        Rails.logger.info({
          event: "github_authentication_successful",
          user_id: current_user.id,
          github_login: current_user.github_username
        }.to_json)
      end

      redirect_to(home_path, notice: "GitHub account linked to @#{current_user.github_username || 'unknown'}!")
    rescue StandardError => e
      Rails.logger.tagged("Authentication") do
        Rails.logger.error({
          event: "github_authentication_failed",
          error: e.message
        }.to_json)
      end
      redirect_to home_path, alert: e.message
    end
  end

  # Logout
  def destroy
    session.delete(:original_id) if session[:original_id]
    terminate_session

    # clear Ahoy cookies
    cookies.delete(:ahoy_visit)
    cookies.delete(:ahoy_visitor)

    redirect_to root_path, notice: "Signed out successfully. Cya!"
  end

  # POST /auth/track
  def track
    email = params[:email]

    if email.present?
      EmailTrack.create(email: email)
      head :ok
    else
      head :bad_request
    end
  end

  def idv
    state = SecureRandom.hex(24)
    session[:idv_state] = state
    @idv_link = current_user.identity_vault_oauth_link(idv_callback_url, state: state)
    render "projects/ship_idv", layout: "application"
  end

  def idv_callback
    begin
      unless params[:state].present? && params[:state] == session[:idv_state]
        redirect_to home_path, alert: "Invalid identity verification session. Please try again."
        return
      end

      session.delete(:idv_state)
      current_user.link_identity_vault_callback(idv_callback_url, params[:code])
    rescue StandardError => e
      event_id = Sentry.capture_exception(e)
      return redirect_to home_path, alert: "Couldn't link identity: #{e.message} (ask support about error ID #{event_id}?)"
    end

    redirect_to home_path, notice: "Successfully linked your identity."
  end

  private

  def redirect_if_logged_in
    return unless user_logged_in?

    redirect_to(post_login_redirect_path || home_path)
  end

  def set_after_login_redirect
    path = safe_redirect_path(params[:redirect_to])
    session[:after_login_redirect] = path if path.present?
  end

  def post_login_redirect_path
    session.delete(:after_login_redirect) || safe_redirect_path(params[:redirect_to])
  end

  def safe_redirect_path(url)
    return nil if url.blank?

    begin
      uri = URI.parse(url)
      if uri.scheme.nil? && uri.host.nil? && uri.path.present? && uri.path.start_with?("/")
        return uri.path + (uri.query.present? ? "?#{uri.query}" : "")
      end
    rescue URI::InvalidURIError
    end

    nil
  end

  def send_otp(email)
    otp = OneTimePassword.create!(email: email)
    otp.send!
  end

  def validate_otp(email, otp)
    OneTimePassword.valid?(otp, email)
  end
end
