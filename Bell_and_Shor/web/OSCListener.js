var example = example || {};

(function () {
    "use strict";
    example.OSCListener = function () {
        this.oscPort = new osc.WebSocketPort({
            url: "ws://localhost:8081"
        });

        this.listen();
        this.oscPort.open();

        this.oscPort.socket.onmessage = function (e) {
            // console.log("message", e);
        };

        // this.valueMap = {
        //     "/knobs/0": carrierSpec.freq,
        //     "/fader1/out": carrierSpec.freq,
        //
        //     "/knobs/1": carrierSpec.mul,
        //     "/fader2/out": carrierSpec.mul,
        //
        //     "/knobs/2": modulatorSpec.freq,
        //     "/fader3/out": modulatorSpec.freq,
        //
        //     "/knobs/3": modulatorSpec.mul,
        //     "/fader4/out": modulatorSpec.mul
        // };
    };

    example.OSCListener.prototype.listen = function () {
        // this.oscPort.on("message", this.mapMessage.bind(this));
        this.oscPort.on("message", function (msg) {
            console.log("message", msg);
        });
    };

    // example.SocketSynth.prototype.mapMessage = function (oscMessage) {
    //     $("#message").text(fluid.prettyPrintJSON(oscMessage));

        // var address = oscMessage.address;
        // var value = oscMessage.args[0];
        // var transformSpec = this.valueMap[address];
        //
        // if (transformSpec) {
        //     var transformed = transformSpec.transform(value);
        //     this.synth.set(transformSpec.inputPath, transformed);
        // }
    // };

}());