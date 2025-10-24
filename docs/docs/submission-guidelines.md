| title       | Submission guidelines                              |
| ----------- | -------------------------------------------------- |
| description | Guidelines for submitting your project to the site |
| priority    | 1                                                  |


## Think you're ready to ship? Read this!

When you do the ship flow, your repository is already verified to have certain files such as a 
- BOM.csv
- ReadMe.md



Along with some other requirements. However, in order to have a project be truly "shipped", there are some other requirements that are harder to automatically check. 

-----------

### 1) Original project 

If you follow guides from online or even from the [guides](/guides), thats fine! However, you need have an original touch to the project. This is something different for every project. For the split keyboard, maybe add lights that flash different colors based on the program, etc. We WILL verify that your project is original even if you create it from some obscure guide.

-----------

### 2) Polished project

This means that you have a nice looking ReadMe.md, all of your required files (see below), a good description of what the project is for and how to use the files to recreate the project. You should render or screenshot any of the 3d models for the projects and once you build the project, add a GIF or video of the project working. 

  **Here are some great examples of shipped projects**. Notice how the files are organized using folders, and, more importantly, it’s well documented what the project is about and what you can do with it!

  **Keyboards & Macropads:**

- [Seigaiha Keyboard](https://github.com/yiancar/Seigaiha)
- [Ducky Pad](https://github.com/dekuNukem/duckyPad)

**3D printers:**

- [Voron 0](https://github.com/VoronDesign/Voron-0)
- [Annex K3](https://github.com/Annex-Engineering/Gasherbrum-K3)

**Misc projects:**

- [PiGRRL](https://github.com/adafruit/Adafruit-PiGRRL-PCB) Game console
- [Nevermore filters](https://github.com/nevermore3d/Nevermore_Micro) (I’ll admit - this one is a little excessive)

**When you make your repository nothing but a dump of files and 2 sentences for a README**, what happens is that it’s hard for other people to recognize your work, nor does it make it easy to learn from. *It’s not real*. It only lives on in your tiny corner of this earth.


-----------

### 3) Required files 

Your repo should look like this:

#### Root Directory
-  `README.md` contains:
  -  A short description of what your project is
  -  A couple sentences on *why* you made the project
  -  Screenshot of full 3D model
  -  Screenshot of PCB (if applicable)
  -  Wiring diagram (if applicable)
  -  BOM in table format at the end of the README
-  `JOURNAL.md` contains:
  -  Total time spent on the project at the top
  -  Dates
  -  Time spent per day
  -  Pictures/videos of work in progress
-  `BOM.csv` [make sure to have all required parts!](https://blueprint.hackclub.com/docs/bom)
      
####  /CAD
-  Complete CAD assembly with all components (including electronics)
-  `.STEP` file of the full 3D CAD model
-  Source design files (e.g., `.f3d`, `.FCStd`)
-  (Optional) 3D render of your project

#### /PCB
-  `.kicad_pro` (KiCad project file)
-  `.kicad_sch` (schematic)
-  `.kicad_pcb` (PCB)
-  `gerbers.zip` or equivalent
- `.wrl` 3D Model of your PCB

####  /Firmware
-  Firmware present (even if untested)
-  Any libraries or dependencies used

#### YOU *DO NOT* HAVE:
-  AI Generated READMEs or Journal entries
-  Stolen work from other people
-  missing firmware/software

Projects containing these issues may be permanently rejected and could result in a ban from Blueprint and other Hack Club programs.

The required files may depend on your project type. For typical PCB projects it even differs on KiCAD vs EasyEDA. A good rule of thumb is to upload **AT LEAST** the files required to fully recreate the project. For KiCAD, you will need:

- `.kicad_pcb`, file representing the KiCad PCB Layout
- `.kicad_sch`, for your schematic
- `.kicad_pro`, your project file
- `.wrl` 3D Model of your PCB

For EasyEDA, you will need your:
- Gerber
- Pick an place



Add `.step` files for any CAD and assemblies. Add `.obj` or `.stl` files for any other 3d models. Bonus if you have all three.

You can additional link to your Onshape document.

All projects should also have 
  - Some pictures of the design (hopefully you have some cool renders)



### 4) A Good Journal

Your journal is very important for Blueprint! Not only does it allow us to verify the hours you spent, it also allows for other people to look back at your project and follow it's journey. Here are some important things to keep in mind while journaling:
- Try to keep each entry under 5 hours, this is not a hard requirement but your project will be more likely to be rejected
- Take into account your thoughts while making a project
- Don't just log the steps that led to your final project! You should have all of your failures and rabbit holes that didn't end up making it to the final piece.

There is no one thing that makes a Journal "Good" but a follow the suggestions above and your project is likely to be approved!



Once you meet all of the requirements, your project is good to submit!

### 5) Cost Optimized

Of course you should always aim to make your project as cheap as possible but there are some specific requirements for cost: 

- Always get the minimum quantity of your project. We are funding your project to learn not to mass-produce things like merch. On JLCPCB for example, this means only 5 PCB's, or 2 PCBA's. 

- JLCPCB Specific: Always choose parts for your PCB which allow you to use economic assembly rather than standard. Try and keep your PCB under 100x100mm if possible and choose Global Standard Direct shipping when you can.
