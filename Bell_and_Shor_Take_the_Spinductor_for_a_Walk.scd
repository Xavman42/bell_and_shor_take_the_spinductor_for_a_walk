~nn.write("net1.json".resolveRelative); // Save a neural net (spinductor)
~nn.read("net1.json".resolveRelative); // Open a neural net (spinductor)
~spinductor.tare; // Tare the spindcutor

SerialPort.closeAll; // May need to manually close SerialPorts if spinductor malfunctions.
(
// ServerOptions.outDevices;
s.options.sampleRate = 48000;
s.options.outDevice_("ASIO : MOTU Pro Audio");
~outputChannels = 3; // Set this to 2 for a stereo mixdown
s.options.numOutputBusChannels = ~outputChannels;
~comPort = "COM6"; // What com port is listening for the spinductor?
~send_OSC_to_browser = false; // If you run the node.js server, set this to true to send data over there for visualization in the browser. This check was implemented to get around some annoying error messages that would fire whenever an OSC message failed to be delivered to the browser.

~starting_number = 0;
~outputParams = 18;
~rhythmic_stability_parameter = 0.0; // Use 0 or positive number - larger number wider random range
~wait_parameter = 1; // Use positive fraction NOT ZERO
~melody_speed_parameter = 1.1; // Use positive fraction NOT ZERO
~pitch_parameter = 0; // Probably don't mess with this
s.waitForBoot{
	// Here's where we make some effects! They should all be 3 channels by default.
	SynthDef(\delay, {arg bus, out=0, delaytime=0.2, decaytime=4, mix=0.0;
		var sig, dry;
		mix = mix.lag(1.0);
		delaytime = delaytime.lag(0.01);
		decaytime = decaytime.lag(0.01);
		sig = In.ar(bus, 3);
		dry = sig;
		sig = CombN.ar(Decay.ar(sig, 0.5), delaytime, delaytime, decaytime);
		sig = XFade2.ar(dry, sig, mix.linlin(0.0, 1.0, -1.0, -0.5));
		sig = Compander.ar(sig, sig, 0.1, 1, 0.1, 0.01, 0.01);
		Out.ar(out, sig);
	}).add;
	SynthDef(\filter, {arg bus, out, freq=440, q=0.1, mix=0.0;
		var sig, dry;
		mix = mix.lag(1.0);
		freq = freq.lag(0.01);
		q = q.lag(0.01);
		sig = In.ar(bus, 3);
		dry = sig;
		sig = BPF.ar(sig, freq, q.reciprocal);
		sig = XFade2.ar(dry, sig, mix.linlin(0.0, 1.0, -1.0, 1.0));
		Out.ar(out, sig);
	}).add;
	SynthDef(\reverb, { |bus, out, predelay = 1, revtime = 10, lpf = 500, amp = 1, mix = 0.0, lag = 2|
		var dry, wet, temp, sig;
		dry = In.ar(bus, 3);
		temp = In.ar(bus, 3);
		wet = 0;
		temp = DelayN.ar(temp, 0.2, predelay.varlag(lag));
		32.do {temp = AllpassN.ar(temp, 0.05, {Rand(0.001, 0.05)}, revtime.varlag(lag));
			temp = LPF.ar(temp, lpf.varlag(lag));
			wet = wet + temp;
		};
		sig = XFade2.ar(dry, wet, mix.varlag(lag)*2-1, amp.varlag(10));
		sig = Limiter.ar(sig, -10.dbamp, 0.001);
		sig = sig * amp.varlag(10);
		Out.ar(out, sig);
	}).add;
	// This SynthDef handles all the sound generation and neural networking stuff.
	SynthDef(\tone, {
		arg curve=4.0.neg, channel=0, mix=0.1, freq=440, outbus=0;
		var sig, sig1, sig2, core1, core2, freq1, freq2, feed1, feed2, dsig, iEnv, env, car, mod;
		var val = FluidBufToKr.kr(\nnBuf.kr(0), 0, ~outputParams), phase1, phase2;
		/*
		0- baseFreq2
		1- fb1
		2- fb2
		3- oscillator
		4- loFold
		5- hiFold
		6- filter frequency
		7- filter resonance
		8- envelope index
		9- index scale
		10- index attack time
		11- index release time
		12- carrier attack
		13- carrier release
		14- modulator ratio
		15- carrier ratio
		16- attack time
		17- release time
		*/

		iEnv = EnvGen.kr(
			Env.new(
				[val[8]+0.01, val[8] * val[9]+0.01, 0],
				[val[10]+0.01, val[11]+0.01],
				[val[12]+0.01, val[13]+0.01]
			)
		);

		env = EnvGen.kr(Env.perc(attackTime: val[16]/4+0.001, releaseTime: (val[17]+0.1)/2, curve:[0.1, 1]), doneAction: 2);
		mod = SinOsc.ar(freq * val[3], mul: freq * val[14] * iEnv);
		car = SinOsc.ar(freq * val[15] + mod);
		sig2 = car;

		#feed1, feed2 = LocalIn.ar(2);

		freq1 = freq + (feed2 * (val[1].pow(2) * 1000));
		freq2 = val[0].linexp(0, 1, 10, 2000) + (feed1 * (val[2].pow(2) * 1000));

		phase1 = Phasor.ar(0.0, freq2/SampleRate.ir, 0.0, 2pi);
		phase2 = Phasor.ar(phase1 < 0.001, freq1/SampleRate.ir, 0.0, 2pi);
		core1 = phase1.sin;
		core2 = phase2.sin;

		LocalOut.ar([core1, core2]);

		sig1 = SelectX.ar(val[3], [core1, core2]);

		sig1 = Fold.ar(sig1, val[4] * -1, val[5]);
		sig1 = MoogFF.ar(sig1, val[6].linexp(0, 1, 20, 12000), val[7] * 4);

		sig = XFade2.ar(sig1, sig2, mix.linlin(0.0, 1.0, -1.0, 1.0));
		sig = sig * env * 0.8;

		sig = LeakDC.ar(sig) * env;
		sig = Select.ar( ~outputChannels-2,
			[
				Select.ar(
					channel,
					[
						Pan2.ar(sig, -1),
						Pan2.ar(sig, 0),
						Pan2.ar(sig, 1)
				]),
				Select.ar(
					channel,
					[
						Pan4.ar(sig, -1, 1),
						Pan4.ar(sig, 1, 1),
						Pan4.ar(sig, -1, -1)
				])
		]);
		Out.ar(outbus, sig);
	}).add;
	s.sync;
	~reverb_bus = Bus.audio(s, 3);
	~filter_bus = Bus.audio(s, 3);
	~delay_bus = Bus.audio(s, 3);
	s.sync;
	~reverb = Synth.new(\reverb, [\bus, ~reverb_bus, \out, 0]);
	~filter = Synth.new(\filter, [\bus, ~filter_bus, \out, ~reverb_bus]);
	~delay = Synth.new(\delay, [\bus, ~delay_bus, \out, ~filter_bus]);
	s.sync;
	~synth = Synth(\tone, [nnBuf: ~ctrlBuf, outBus: 0]);

	if (~send_OSC_to_browser) {~browser_address = NetAddr.new("127.0.0.1", 57121)};    // create the NetAddr

	~spinductorD = 12;

	~dataArray = Array.fill(~spinductorD, { 0 });

	~masterBus = Bus.audio(s, 2);
	~synthGroup = Group.new(s);

	~ds_input = FluidDataSet(s);
	~ds_output = FluidDataSet(s);

	~inputBuf = Buffer.alloc(s, ~spinductorD);
	~ctrlBuf = Buffer.loadCollection(s,{rrand(0.0,1.0)} ! ~outputParams);
	~ctrlBuf = Buffer.loadCollection(s, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0.01, 0.4]);

	~nn = FluidMLPRegressor(s,[7],FluidMLPRegressor.sigmoid,FluidMLPRegressor.sigmoid,learnRate:0.1,batchSize:1,validation:0);
	// The following block of code gets data from the Spinductor
	if (SerialPort.devices.any(_ == ~comPort)){

		~spinductor = Spinductor.new(~comPort); // Update string accordingly
		~spinductor.listen;

		{
			4.wait;
			if (~spinductor.isNil == false) {~spinductor.tare};
		}.fork;
		~spinductor.debug;



		~stream_data = Routine.new({
			var ascii, func, offset, lowSat, hiSat;
			{
				// ~spinductor.debug;
				lowSat = -20;
				hiSat = 20;
				if (~spinductor.isNil == false) {
					~spinductor.values.keysValuesDo({ | key, value, i|
						~dataArray[i] = value.asFloat;
						// ~dataArray.postln;
					});
					{~inMultisliderview.value_((~dataArray * 0.125) + 0.5)}.defer
				};
				~dataArray.do({ | value, i |
					~inputBuf.set(i, value);
				});
				if(~predicting,{
					~nn.predictPoint(~inputBuf,~ctrlBuf,{

						~ctrlBuf.getn(0,~outputParams,{
							arg prediction_values;
							{~outMultisliderview.value_(prediction_values)}.defer;
						});
					});
				});
				if (~send_OSC_to_browser) {
					~spinductor.values.keysValuesDo({ | key, value, i|
						switch (key)
						{\topX} {
							~browser_address.sendMsg(\m0, value.linlin(lowSat, hiSat, 0, 2pi));
						}
						{\topY} {
							~browser_address.sendMsg(\m1, value.linlin(lowSat, hiSat, 0, 2pi));

						}
						{\topZ} {
							~delay.set(\delaytime, value.linexp(lowSat, hiSat, 0.001, 1.0)); // Greater than 0
							~browser_address.sendMsg(\m2, value.linlin(lowSat*1.5, hiSat*1.5, 0, 2pi));
						}
						{\frLX} {
							~browser_address.sendMsg(\m3, value.linlin(lowSat, hiSat, 0, 2pi));

						}
						{\frLY} {
							~browser_address.sendMsg(\m4, value.linlin(lowSat, hiSat, 0, 2pi));

						}
						{\frLZ} {
							~delay.set(\decaytime, value.linlin(lowSat, hiSat, 0.1, 2.0)); // Greater than 0
							~browser_address.sendMsg(\m5, value.linlin(lowSat*1.5, hiSat*1.5, 0, 2pi));
						}
						{\baRX} {
							~browser_address.sendMsg(\m6, value.linlin(lowSat, hiSat, 0, 2pi));
						}
						{\baRY} {
							~browser_address.sendMsg(\m7, value.linlin(lowSat, hiSat, 0, 2pi));
						}
						{\baRZ} {
							~reverb.set(\revtime, value.linlin(lowSat, hiSat, 0.1, 4));
							~browser_address.sendMsg(\m8, value.linlin(lowSat*1.5, hiSat*1.5, 0, 2pi));
						}
						{\baLX} {
							~browser_address.sendMsg(\m9, value.linlin(lowSat, hiSat, 0, 2pi));
						}
						{\baLY} {
							~browser_address.sendMsg(\m10, value.linlin(lowSat, hiSat, 0, 2pi));
						}
						{\baLZ} {
							~reverb.set(\lpf, value.linexp(lowSat, hiSat, 100, 2000));
							~browser_address.sendMsg(\m11, value.linlin(lowSat*1.5, hiSat*1.5, 0, 2pi));
						};
					});
					~browser_address.sendMsg(\tog1, ~spinductor.buttons[\tog1]);
					~browser_address.sendMsg(\tog2, ~spinductor.buttons[\tog2]);
					~browser_address.sendMsg(\tog3, ~spinductor.buttons[\tog3]);
					~browser_address.sendMsg(\but1, ~spinductor.buttons[\but1]);
					~browser_address.sendMsg(\but2, ~spinductor.buttons[\but2]);
					~browser_address.sendMsg(\but3, ~spinductor.buttons[\but3]);
				};
				0.005.wait;
				~reverb.set(\amp, ~spinductor.buttons[\tog1]);
				~delay.set(\mix, ~spinductor.buttons[\tog2]);
				~reverb.set(\mix, ~spinductor.buttons[\tog3]);
				if (~spinductor.buttons[\but1] == 1) { ~count = 1; };
				if (~spinductor.buttons[\but2] == 1) { ~count = 500; };
				if (~spinductor.buttons[\but3] == 1) { ~count = 10000; };
			}.loop;
		});
	};
	~prime=0;
	~file = SemiColonFileReader.read("csvdata.csv".resolveRelative, true, true);
	~file[0].postln;
	OSCdef.freeAll;

	// The following is just for parsing the list of prime numbers into an array.

	~func = { arg in_num=4;
		var bad_list, good_list, num, bad_char;
		~file[in_num-1][5];
		bad_list = ~file[in_num-1][5].asList;
		good_list = [];
		~com = 0;
		num="";
		for(0, bad_list.size, { arg i;
			bad_char = bad_list[i];
			if(bad_char==$,)
			{
				~com=0;
				good_list = good_list.add(num.asInteger);
				num="";
			};
			if(bad_char==$0){num=num++bad_char.digit.asString;};
			if(bad_char==$1){num=num++bad_char.digit.asString;};
			if(bad_char==$2){num=num++bad_char.digit.asString;};
			if(bad_char==$3){num=num++bad_char.digit.asString;};
			if(bad_char==$4){num=num++bad_char.digit.asString;};
			if(bad_char==$5){num=num++bad_char.digit.asString;};
			if(bad_char==$6){num=num++bad_char.digit.asString;};
			if(bad_char==$7){num=num++bad_char.digit.asString;};
			if(bad_char==$8){num=num++bad_char.digit.asString;};
			if(bad_char==$9){num=num++bad_char.digit.asString;};
		});
		good_list = good_list.add(num.asInteger);
		good_list;
	};

	~counter = 0;
	// The following generates an interface for training a neural net on the spinductor.
	if (~spinductor.notNil) {
		~predicting = false;
		~win = Window("MLP Regressor",Rect(0,0,1000,400));

		~outMultisliderview = MultiSliderView(~win,Rect(0,0,400,400))
		.size_(~outputParams)
		.elasticMode_(true)
		.action_({
			arg msv;
			~ctrlBuf.setn(0,msv.value);
		});

		~inMultisliderview = MultiSliderView(~win, Rect(400,0,400,400))
		.size_(12)
		.elasticMode_(true)
		.action_({
			arg msv;
			~inputBuf.setn(0,msv.value);
		});

		Button(~win,Rect(800,0,200,20))
		.states_([["Add Points"]])
		.action_({
			arg but;
			var id = "example-%".format(~counter);
			~ds_input.addPoint(id,~inputBuf);
			~ds_output.addPoint(id,~ctrlBuf);
			~counter = ~counter + 1;

			~ds_input.print;
			~ds_output.print;
		});

		Button(~win,Rect(800,20,200,20))
		.states_([["Train"]])
		.action_({
			arg but;
			~nn.fit(~ds_input,~ds_output,{
				arg loss;
				"loss: %".format(loss).postln;
			});
		});

		Button(~win,Rect(800,40,200,20))
		.states_([["Not Predicting",Color.yellow,Color.black],["Is Predicting",Color.green,Color.black]])
		.action_({
			arg but;
			~predicting = but.value.asBoolean;
		});

		Button(~win,Rect(800, 60, 200, 20))
		.states_([["Randomize"]])
		.action_({
			~outputParams.do({ | i | ~ctrlBuf.set(i, rrand(0, 1.0)) });
		});

		~win.front;


		~stream_data.play;
	};




	// Here is where we finally start iterating through the data and making synths.
	~prime=0;
	~main = {
		var list, seq_list, numerator_list, denominator_list;

		r = Routine.new({ var l=0, bind1, bind2;
			~fund1 = 440;
			~a_num = 2;
			~b_num = 2;
			~evaluation_rate = 0.8;
			~melodic_rate = 0.15;
			~count = ~starting_number;
			while {~count < 99999}{
				~count = ~count + 1;
				list = ~func.value(~count);
				~count.post;
				if (~send_OSC_to_browser) {~browser_address.sendMsg("/count", ~count)};
				list.post;
				"     ".post;
				~file[~count-1][4].postln;

				if (~send_OSC_to_browser) {~browser_address.sendMsg(\primeList, list.asString)};
				list = list.copySeries(0, 1, 6); // For the sake of processing in real time, truncate list


				seq_list = [1];
				numerator_list = [1];
				denominator_list = [1];
				if(list.size > 1){ // If the number is not prime
					list.size.factorial.do({ arg i; // Get the total number of possible permutations
						var snip;
						snip = list.permute(i);
						if (~file[~count-1][1][0].digit == 1) // If the measurement is 1, Otonal series
						{
							if (snip[0] > snip[1]){ var rat;
								rat = snip[0]/snip[1];
								numerator_list = numerator_list.add(snip[0]);
								denominator_list = denominator_list.add(snip[1]);
								while({rat > 5}, {rat = rat/2;});
								seq_list = seq_list.add(rat);
								// ~browser_address.sendMsg("/ratio", rat);
							};
						}
						{ // Else if the measurement is 0, Utonal series
							if (snip[0] < snip[1]){ var rat;
								rat  = snip[0]/snip[1];
								numerator_list = numerator_list.add(snip[0]);
								denominator_list = denominator_list.add(snip[1]);
								while({rat < 0.1}, {rat = rat*2;});
								seq_list = seq_list.add(rat);
								// ~browser_address.sendMsg("/ratio", rat);
							};
						}
					});

					// Note if factors are of the form a^b
					if([list[0]].dupEach(list.size) == list){
						list[0].post;
						" to the power of ".post;
						list.size.postln;
						// The following two lines kinda suck
						~evaluation_rate = 2*(list[0].wrap(1, 7).reciprocal);
						~melodic_rate = list.size.wrap(1,13).reciprocal/1.15;
					}
				}
				{ // If prime, generate new fundamental
					~prime=list[0];
					~fund1 = (440 * list[0]);
					while({~fund1 > 600}, {~fund1=~fund1/4;});
					~browser_address.sendMsg(\prime, ~prime);
				};

				seq_list = seq_list.copySeries(0, 1, 299); // Truncate lists longer than 300 values
				numerator_list = numerator_list.copySeries(0, 1, 299);
				denominator_list = denominator_list.copySeries(0, 1, 299);
				bind1 = Pbind(\instrument, \tone,
					\freq, Pseq(~fund1*seq_list)+~pitch_parameter,
					\nnBuf, ~ctrlBuf,
					\dur, Pseq(Array.fill(seq_list.size, {~melodic_rate*~melody_speed_parameter + ~rhythmic_stability_parameter.rand2})),
					\mul, Pseq(Array.fill(seq_list.size, {arg i; 0.2/((i+1).pow(0.2))})),
					\channel, ~file[~count-1][2].asInteger,
					\outbus, ~delay_bus,
					\numerator, Pseq(numerator_list),
					\denominator, Pseq(denominator_list),
					\prime, ~prime,
					\post, Pfunc { |event| ~browser_address.sendMsg((event.channel.asString + "voice1").asSymbol, event.numerator.asString + "/" + event.denominator.asString, event.prime);}
				);



				seq_list = [1]; // Clear sequence list and start again
				numerator_list = [1];
				denominator_list = [1];
				if(list.size > 1){ // If the number is not prime
					list.size.factorial.do({ arg i; // Get the total number of possible permutations
						var snip;
						snip = list.permute(i);
						if (~file[~count-1][1][1].digit == 1) // If the measurement is 1, Otonal series
						{
							if (snip[0] > snip[1]){ var rat;
								rat = snip[0]/snip[1];
								numerator_list = numerator_list.add(snip[0]);
								denominator_list = denominator_list.add(snip[1]);
								while({rat > 5}, {rat = rat/2;});
								seq_list = seq_list.add(rat);
							};
						}
						{ // If the measurement is 0, Utonal series
							if (snip[0] < snip[1]){ var rat;
								rat  = snip[0]/snip[1];
								numerator_list = numerator_list.add(snip[0]);
								denominator_list = denominator_list.add(snip[1]);
								while({rat < 0.1}, {rat = rat*2;});
								seq_list = seq_list.add(rat)
							};
						}
					});
				};
				seq_list = seq_list.copySeries(0, 1, 299); // Truncate lists longer than 300 values
				numerator_list = numerator_list.copySeries(0, 1, 299);
				denominator_list = denominator_list.copySeries(0, 1, 299);
				~fund2 = ~fund1*1/2;
				bind2 =
				Pbind(\instrument, \tone,
					\freq, Pseq(~fund2*seq_list)+~pitch_parameter,
					\nnBuf, ~ctrlBuf,
					\dur, Pseq(Array.fill(seq_list.size, {~melodic_rate*~melody_speed_parameter+ ~rhythmic_stability_parameter.rand2})),
					\mul, Pseq(Array.fill(seq_list.size, {arg i; (0.2/((i+1).pow(0.2)))})),
					\channel, ~file[~count-1][3].asInteger,
					\outbus, ~delay_bus,
					\numerator, Pseq(numerator_list),
					\denominator, Pseq(denominator_list),
					\prime, ~prime,
					\post, Pfunc { |event| ~browser_address.sendMsg((event.channel.asString + "voice2").asSymbol, event.numerator.asString + "/" + event.denominator.asString, event.prime);}

				);

				Ppar([bind1, bind2]).play;
				if(list.size == 1) {(~evaluation_rate*~file[~count-1][4].asFloat*2*~wait_parameter).yield}; // If prime, pause a little longer
				(~evaluation_rate*~file[~count-1][4].asFloat*2*~wait_parameter).yield; // Fluctuations in rhythm correspond to correlation factor
			};
		});
		r.play;
	};
	3.wait;
	~main.play;

});