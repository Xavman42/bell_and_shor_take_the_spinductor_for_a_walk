let font;
let particles = [];
let count = 0;
let prime = 1;
let primeList = "";
let alphaFadeRate = 5;
let blochSphereRadius = 100;
let primeColorNumber = 0;
let primeColor = "white";
let mags = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
let arrowsX = [-400, -400, -400, -150, -150, -150, 150, 150, 150, 400, 400, 400];
let arrowsY = [-200, 0, 200, -200, 0, 200, -200, 0, 200, -200, 0, 200];
// let arrowsX = [-400, -150, 150, 400, -400, -150, 150, 400, -400, -150, 150, 400];
// let arrowsY = [-200, -200, -200, -200, 0, 0, 0, 0, 200, 200, 200, 200];
let radius = 40;
// let primeColor = [0, 0, 0];
let poses = [];
let easing = false;
let throbbing = false;
let draw_coords = [];


function seededRandom(seed) {
    let x = (Math.sin(seed) * 10000)/2 + 0.5;
    return (x) % 1;
}

function mapFloatToInt(value, min, max) {
    return Math.round((value * (max - min + 1)) + min);
}

function smoke(msg, x, y, primeColorNumber) {
    const osc_points = font.textToPoints(
        String(msg['args'][0]), 0, 0, 30, { // Here is the font size
            sampleFactor: 0.25,
            simplifyThreshold: 0
        });
    for (let i = 0; i < osc_points.length; i++){
        if (particles.length > 5000) {break;}
        let p = new Particle(x+osc_points[i].x, y+osc_points[i].y, primeColorNumber);
        particles.push(p);
    }
}
OSCListener.oscPort.on("message", function (msg) {
    // console.log("message", msg['args'][0]);
    if (msg['address'] === "/0 voice1") {
        smoke(msg, -350 - Math.random()*200, -250 + Math.random()*200, msg['args'][1]);
    } else if (msg['address'] === "/0 voice2") {
        smoke(msg, -250 + Math.random()*200, -250 + Math.random()*200, msg['args'][1]);
    } else if (msg['address'] === "/1 voice1") {
        smoke(msg, 250 - Math.random()*200, -250 + Math.random()*200, msg['args'][1]);
    } else if (msg['address'] === "/1 voice2") {
        smoke(msg, 350 + Math.random()*200, -250 + Math.random()*200, msg['args'][1]);
    } else if (msg['address'] === "/2 voice1") {
        smoke(msg, -100 - Math.random()*200, 150 + Math.random()*200, msg['args'][1]);
    } else if (msg['address'] === "/2 voice2") {
        smoke(msg, 100 + Math.random()*200, 150 + Math.random()*200, msg['args'][1]);
    } else if (msg['address'] === "/count") {
        count = msg['args'][0];
    } else if (msg['address'] === "/prime") {
        prime = msg['args'][0];
        primeColorNumber = parseInt(msg['args'][0]);
    } else if (msg['address'] === "/primeList") {
        primeList = msg['args'][0];
    }
    else if (msg['address'] === "/m0") {
        mags[0] = msg['args'][0];
    } else if (msg['address'] === "/m1") {
        mags[1] = msg['args'][0];
    } else if (msg['address'] === "/m2") {
        mags[2] = msg['args'][0];
    } else if (msg['address'] === "/m3") {
        mags[3] = msg['args'][0];
    } else if (msg['address'] === "/m4") {
        mags[4] = msg['args'][0];
    } else if (msg['address'] === "/m5") {
        mags[5] = msg['args'][0];
    } else if (msg['address'] === "/m6") {
        mags[6] = msg['args'][0];
    } else if (msg['address'] === "/m7") {
        mags[7] = msg['args'][0];
    } else if (msg['address'] === "/m8") {
        mags[8] = msg['args'][0];
    } else if (msg['address'] === "/m9") {
        mags[9] = msg['args'][0];
    } else if (msg['address'] === "/m10") {
        mags[10] = msg['args'][0];
    } else if (msg['address'] === "/m11") {
        mags[11] = msg['args'][0];
    }
    else {
        smoke(msg, Math.floor(Math.random()*1920/2), Math.floor(Math.random()*1080/2));
    }
    // draw_coords = [];
    // for (let j = 0; j < 12; j++) {
    //     for (let i = 0; i < 12; i++) {
    //         append(draw_coords,  [mags[j], mags[i]]);
    //     }
    // }
});

function preload() {
    font = loadFont('./assets/Avenir.otf');
}

function setup() {
    createCanvas(1920/2, 1080/2, WEBGL);
    textFont(font);
    textSize(36);
    const points = font.textToPoints(
        'click', 0, 0, 50, {
            sampleFactor: 1,
            simplifyThreshold: 0
        });
}

function draw() {
    background(0);
    ambientLight(166);
    directionalLight(255, 255, 255, 1, 1, -1);

    // console.log(frameRate());
    stroke(primeColor);
    for (let i = 0; i < 12; i++) {
        line(arrowsX[i], arrowsY[i], arrowsX[i] + radius * cos(mags[i]), arrowsY[i] + radius * sin(mags[i]));
        arrowHead(createVector(-arrowsX[i], -arrowsY[i]),
            createVector(radius * cos(mags[i]), radius * sin(mags[i])));
    }
    if (frameRate() > 60) {
        alphaFadeRate -= 2;
    } else if (frameRate() < 30) {
        alphaFadeRate += 4;
    } else if (frameRate() < 20) {
        alphaFadeRate += 8000;
    }
    for (let i = particles.length - 1; i >= 0; i--) {
        particles[i].update();
        particles[i].show();
        if (particles[i].finished()) {
            //remove this particle
            particles.splice(i, 1);
        }
    }
    if (alphaFadeRate < 6) {
        alphaFadeRate = 6;
    }
    if (alphaFadeRate > 30) {
        alphaFadeRate = 30;
    }
    drawCountText();
    drawPrimeText();
    // poses = [];
    // for (let i = 0; i < draw_coords.length; i++) {
    //     poses.push({x: draw_coords[i][0]*480/4-480/2, y: draw_coords[i][1]*270/4-270/2});
    // }
    // if (poses.length > 288) poses.shift();

    // sz=10;
    // for (let p = 0; p < poses.length; p++) {
    //     let pos = poses[p];
    //     let sz = 10;
    //     if(throbbing) sz = sin(frameCount*0.01)*p + p;
    //
    //     Turn on easing
    //     if(easing) {
    //         pos.x+=(mouseX-pos.x)*0.01;
    //         pos.y+=(mouseY-pos.y)*0.01;
    //     }
    //     ellipse(pos.x, pos.y, sz, sz);
    // }
}

function arrowHead(start, vector) {

    push();

    var norm = createVector(vector.x, vector.y);
    norm.normalize();

    applyMatrix(
        norm.x, norm.y,
        -norm.y, norm.x,
        vector.x - start.x,
        vector.y - start.y);
    triangle(0, 6, 12, 0, 0, -6);
    pop();

}

class Particle {
    constructor(x, y, primeC) {
        this.x = x;
        this.y = y;
        this.vx = random(-0.03, 0.03);
        this.vy = random(-0.03, 0.03);
        this.alpha = 255;
        this.col = color(mapFloatToInt(seededRandom(parseInt(primeC)), 140, 255),
            mapFloatToInt(seededRandom(parseInt(primeC+1)), 140, 255),
            mapFloatToInt(seededRandom(parseInt(primeC+2)), 140, 255));
        primeColor = this.col;
    }

    finished() {
        return this.alpha < 0; // This evaluates if this is true or false.
    }

    update() {
        this.x += this.vx;
        this.y += this.vy;
        this.alpha -= alphaFadeRate;
    }

    show() {
        noStroke(); //stroke(255); // Next we will use noStroke(); here.
        fill(this.col);
        this.col.setAlpha(this.alpha);
        ellipse(this.x, this.y, 2);
    }
}

function drawCountText() {
    fill(255);
    text(count, -280, 220);
}

function drawPrimeText() {
    const col = color(mapFloatToInt(seededRandom(parseInt(primeColorNumber)), 140, 255),
        mapFloatToInt(seededRandom(parseInt(primeColorNumber+1)), 140, 255),
        mapFloatToInt(seededRandom(parseInt(primeColorNumber+2)), 140, 255));
    fill(255);
    text(prime.toString(), 280, 220);
    fill(col);
    const primeListArray = primeList.slice(1, -1).split(",");
    // console.log(primeListArray)
    const placementInterval = 80;
    let offset = 0
    if (primeListArray.length%2 === 0) {
        offset = - placementInterval * primeListArray.length/2 + placementInterval/2
    } else {
        offset = - placementInterval * (primeListArray.length-1)/2
    }
    for (let i = 0; i < primeListArray.length; i++) {
        text(primeListArray[i], offset + placementInterval * i, -210);
    }
}

function mousePressed() {
    if (mouseX > 0 && mouseX < windowWidth && mouseY > 0 && mouseY < windowHeight) {
        let fs = fullscreen();
        fullscreen(!fs);
    }
}

function windowResized() {
    resizeCanvas(windowWidth, windowHeight);
}
