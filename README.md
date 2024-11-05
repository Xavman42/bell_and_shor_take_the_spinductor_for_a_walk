_Bell and Shor Take the Spinductor for a Walk_

This is an audio-visual installation piece utilizing quantum algorithms (or at least classical approximations for now) and a new instrument called the spinductor. 
A short video excerpt me exploring sounds in the piece is here: https://youtu.be/DJmhF-TOFrk 

Without getting too much into the artistic motivations behind this piece, here's how you can get it up and running on your device...

**Generating Prime Numbers (and other numbers)**

The intervallic (pitch) material in the piece is derived from making fractions out of prime numbers. 
The convenient side-effect of this approach is that the piece is effectively just-intonated.
To generate these prime numbers, what I do is count from 1 to 100,000 or so and figure out what prime numbers can be multiplied together to get the current count.
For example, the prime factors of 42 are 2, 3, and 7.
I generate some other numbers inspired by Bell's inequality which we'll use later to control spatialization and melodic direction in the piece.

To generate a (poorly formatted) list of numbers and their prime factors (and other Bell-style test data), you'll need the three Python scripts, namely `main_data_generator.py` and its dependencies: `prime_test.py` and `shors_v2.py`.
You'll need a few third party dependencies as well, but your IDE should tell you what you need to install. (Things like NumPy, Qiskit, and Qiskit_aer)
Once you run main_data_generator.py, you'll have created a .csv file. If you wanted to, you could open it up in excel, but it won't look great by default.

**Sonification**

Audio synthesis and processing is handled entirely by SuperCollider. 
There are two extensions you'll need to install to get this up and running. 
The first is FluCoMa, which handles neural networking stuff.
The installation process for FluCoMa is documented here: https://learn.flucoma.org/installation/sc/
Essentially, download and unzip the file, then put it in your extension directory.

The second extension you need is a class which handles the spinductor. 
While there's a very good chance you don't own your own spinductor, it is pretty baked into the code at this point, and I'm not confident this SuperCollider code will run without it.
To install the class, download Spinductor.sc and save it in the same extension directory where you put the FluCoMa folder.

With those two extensions installed, you should in principle be able to run Bell_and_Shor_Take_the_Spinductor_for_a_Walk.scd.
Click somewhere after line 6, hit Ctrl/CMD+ENTER, and you should hear some sine-tones that will keep doing their thing for a day or so.
I tried to be verbose in my comments and naming-conventions, but it's sloppy code for sure. 
I think it's understandable, but I wouldn't use this as a reference for good coding practice in SuperCollider.

**Visualization**

The last piece of the puzzle is a simple visualization of some of the interval ratios generated in the piece.
If you set ~send_OSC_to_browser = true; in line 13 of Bell_and_Shor_Take_the_Spinductor_for_a_Walk.scd, then SuperCollider will begin sending a slew of OSC messages to a local IP address.
This project is what I used to learn JavaScript, so I can't help much if you run into issues getting this setup.
In principle, all you need to do to get this running is install node.js, p5.js, and any other dependencies I'm forgetting about.
Then, navigate via console to the Bell_and_Shor folder and run node .\index.js to create a local web server.
You can then access the visualizer by going to http://localhost:8081 in your browser.
