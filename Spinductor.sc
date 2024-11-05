Spinductor {
	var <values, <buttons, <serialPort, dataStream, <>baudRate, >debug, dataParser, listenRoutine, <offsets, clock, keys, buttonKeys, tareFlag, buttonParser, autoConfig = true;

	*new { | port |
		^super.new.init(port);
	}

	*showDevices {
		SerialPort.devices.postln;
	}

	init { | port |
		keys = [\topX, \topY, \topZ, \frLX, \frLY, \frLZ, \baLX, \baLY, \baLZ, \baRX, \baRY, \baRZ];
		buttonKeys = [\but1, \but2, \but3, \tog1, \tog2, \tog3];
		values = ();
		offsets = ();
		buttons = ();

		baudRate = 115200;
		serialPort = SerialPort.new(port, baudRate);
		dataStream = Array.newClear();

		buttonKeys.do({ | key |
			buttons.put(key, 0);
		});

		keys.do({ | key |
			values.put(key, 0);
			offsets.put(key, 0);
		});

		dataParser = { | key |
			var val = String.new();
			dataStream.do({ | i | val = val++i });
			val = val.asFloat;
			val = val.cbrt;

			values.put(key, (val - offsets[key]));
			dataStream = Array.newClear();
		};

		buttonParser = { | key, state |
			buttons.put(key, state);
		};

		clock = TempoClock.new(1000);
		clock.permanent_(true);

		listenRoutine = r{
			var ascii;
			loop {
				ascii = serialPort.read.asAscii;
				if (debug == true) {this.debug};

				if (ascii.asString == "-" || ascii.asString == "." || ascii.isDecDigit)
				{ dataStream = dataStream.add(ascii.asString) } {
					switch (ascii.asString)
					{"a"} { dataParser.(\topX) }
					{"b"} { dataParser.(\frLX) }
					{"c"} { dataParser.(\baLX) }
					{"d"} { dataParser.(\baRX) }
					{"e"} { dataParser.(\topY) }
					{"f"} { dataParser.(\frLY) }
					{"g"} { dataParser.(\baLY) }
					{"h"} { dataParser.(\baRY) }
					{"i"} { dataParser.(\topZ) }
					{"j"} { dataParser.(\frLZ) }
					{"k"} { dataParser.(\baLZ) }
					{"l"} { dataParser.(\baRZ) }
					{"m"} { buttonParser.(\but1, 1) }
					{"n"} { buttonParser.(\but1, 0) }
					{"o"} { buttonParser.(\but2, 1) }
					{"p"} { buttonParser.(\but2, 0) }
					{"q"} { buttonParser.(\but3, 1) }
					{"r"} { buttonParser.(\but3, 0) }
					{"s"} { buttonParser.(\tog1, 1) }
					{"t"} { buttonParser.(\tog1, 0) }
					{"u"} { buttonParser.(\tog2, 1) }
					{"v"} { buttonParser.(\tog2, 0) }
					{"w"} { buttonParser.(\tog3, 1) }
					{"x"} { buttonParser.(\tog3, 0) };
				};
			};
		};
	}

	listen {
		listenRoutine.play(clock);
	}

	stopListening {
		serialPort.close;
		listenRoutine.stop;
		// listenRoutine.reset;
	}

	tare {
		values.keysValuesDo({
			| keys, values |
			offsets[keys] = values;
		});
	}

	debug {
		values.postln;
	}

	killSerial {
		serialPort.close;
		serialPort = nil;
	}
}