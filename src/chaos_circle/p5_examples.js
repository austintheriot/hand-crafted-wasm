// pixelated Perlin noise

function setup() {
  createCanvas(400, 400);
  noStroke();
}

function draw() {
  for (var x = 0; x < width; x += 10) {
    for (var y = 0; y < height; y += 10) {
      var c = 255 * noise(0.01 * x, 0.01 * y);
      fill(c);
      rect(x, y, 10, 10);
    }
  }
}

// circle with Perlin noise (p5)

var t;

function setup() {
  createCanvas(400, 400);
  background(255);
  stroke(0, 15);
  noFill();
  t = 0;
}

function draw() {
  translate(width / 2, height / 2);
  beginShape();
  for (var i = 0; i < 200; i++) {
    var ang = map(i, 0, 200, 0, TWO_PI);
    var rad = 200 * noise(i * 0.01, t * 0.005);
    var x = rad * cos(ang);
    var y = rad * sin(ang);
    curveVertex(x, y);
  }
  endShape(CLOSE);

  t += 1;

  // clear the background every 600 frames using mod (%) operator
  if (frameCount % 600 == 0) {
    background(255);
  }

}

// Bezier curve with Perlin noise:
var t;

function setup() {
  createCanvas(400, 400);
  stroke(0, 18);
  noFill();
  t = 0;
}

function draw() {
  var x1 = width * noise(t + 15);
  var x2 = width * noise(t + 25);
  var x3 = width * noise(t + 35);
  var x4 = width * noise(t + 45);
  var y1 = height * noise(t + 55);
  var y2 = height * noise(t + 65);
  var y3 = height * noise(t + 75);
  var y4 = height * noise(t + 85);

  bezier(x1, y1, x2, y2, x3, y3, x4, y4);

  t += 0.005;

  // clear the background every 500 frames using mod (%) operator
  if (frameCount % 500 == 0) {
    background(255);
  }
}