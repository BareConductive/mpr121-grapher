/*******************************************************************************

 Bare Conductive MPR121 output grapher / debug plotter for TouchBoard and Pi Cap
 -------------------------------------------------------------------------------

 mpr121_grapher.pde - processing grapher for raw data from TouchBoard and Pi Cap

 Requires Processing 3.0+

 Requires controlp5 (version 2.2.5+) to be in your processing libraries folder:
 http://www.sojamo.de/libraries/controlP5/

 Requires osc5 (version 0.9.8+) to be in your processing libraries folder:
 http://www.sojamo.de/libraries/oscP5/

 If connecting via Serial Data requires datastream on the Touch Board:
 https://github.com/BareConductive/mpr121/tree/public/Examples/DataStream

 If connecting via OSC requires picap-datastream-osc on the Pi Cap

 Bare Conductive code written by Stefan Dzisiewski-Smith and Szymon Kaliski.

 This work is licensed under a MIT license https://opensource.org/licenses/MIT

 Copyright (c) 2016, Bare Conductive

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

*******************************************************************************/

import processing.serial.*;
import controlP5.*;
import oscP5.*;
import netP5.*;

import processing.awt.PSurfaceAWT.SmoothCanvas;
import javax.swing.JFrame;
import java.awt.Dimension;
import java.awt.Point;

JFrame displayFrame;
SmoothCanvas smoothCanvas;

public class Line {
  public float left;
  public float right;
  public float top;
  public float bottom;
}


final int baudRate = 57600;

final int numElectrodes  = 12;
final int numGraphPoints = 300;
final int tenBits        = 1024;

final int graphsLeft           = 20;
final int graphsTop            = 50;
final int graphsWidth          = 984;
final int graphsHeight         = 510;
final int numVerticalDivisions = 8;

final int filteredColour   = color(255, 0,   0,   200);
final int baselineColour   = color(0,   0,   255, 200);
final int touchedColour    = color(255, 128, 0,   200);
final int releasedColour   = color(0,   128, 128, 200);
final int textColour       = color(60);
final int touchColourBar   = color(255, 255, 255, 200);
final int touchColourGraph = color(255, 0,   255, 200);
final int releaseColour    = color(255, 255, 255, 200);

final int graphFooterLeft = 20;
final int graphFooterTop  = graphsTop + graphsHeight + 20;

final int numFooterLabels = 6;

boolean serialSelected = false;
boolean oscSelected    = false;
boolean firstRead      = true;
boolean secondRead     = false;
boolean paused         = false;
boolean helpVisible    = false;
boolean cursorVisible  = false;
boolean isResetting    = false;

int resetStartTime;
final int RESET_TIMEOUT = 5000;

String mode = "GRAPHS"; // "GRAPHS", "DARK", "BARS"

ControlP5 cp5;
ScrollableList electrodeSelector, serialSelector;
Textlabel labels[], startPrompt, instructions, pausedIndicator, cursorLabel;
Button oscButton, helpButton, resetButton;

OscP5 oscP5;

Serial inPort;        // the serial port
String[] validSerialList;
String inString;      // input string from serial port
String[] splitString; // input string array after splitting
int lf = 10;          // ASCII linefeed

int[] filteredData, baselineVals, diffs, touchThresholds, releaseThresholds, fakeTouchThresholds, fakeReleaseThresholds, lastFakeTouchThresholds, status, lastStatus;
int[][] filteredGraph, baselineGraph, touchGraph, releaseGraph, statusGraph;
Line[] filteredDataLines, touchLines, releaseLines;

int globalGraphPtr     = 0;
int electrodeNumber    = 0;
int serialNumber       = 4;
int lastMillis         = 0;
int mouseOverElectrode = -1;
int lastClickY         = 0;

int DEFAULT_WIDTH  = 1024;
int DEFAULT_HEIGHT = 600;
int prevWidth      = 0;
int prevHeight     = 0;

void setup() {
  size(1024, 600);

  smoothCanvas = (SmoothCanvas) getSurface().getNative();
  displayFrame = (JFrame) smoothCanvas.getFrame();
  displayFrame.setMinimumSize(new Dimension(1024, 600));
  displayFrame.setResizable(true);

  // init cp5
  cp5 = new ControlP5(this);

  // setup OSC receiver on port 3000
  oscP5 = new OscP5(this, 3000);

  // init serial
  int validPortCount = 0;
  String[] serialList = Serial.list();

  for (int i = 0; i < serialList.length; i++) {
    if (!(serialList[i].toLowerCase().contains("/dev/tty.") || serialList[i].toLowerCase().contains("bluetooth"))) {
      validPortCount++;
    }
  }

  validSerialList = new String[validPortCount];
  validPortCount = 0;

  for (int i = 0; i < serialList.length; i++) {
    if (!(serialList[i].toLowerCase().contains("/dev/tty.") || serialList[i].toLowerCase().contains("bluetooth"))) {
      validSerialList[validPortCount++] = serialList[i];
    }
  }

  readSettings();

  setupGraphs();
  setupStartPrompt();
  setupRunGUI();
  setupLabels();
}

void fullReset() {
  serialSelected = false;
  oscSelected    = false;
  firstRead      = true;
  secondRead     = false;
  paused         = false;
  helpVisible    = false;
  cursorVisible  = false;
  isResetting    = false;
  prevWidth      = 0;
  prevHeight     = 0;
  mode           = "GRAPHS";

  disableRunGUI();
  hideGraphLabels();
  electrodeSelector.hide();
  enableStartPrompt();
}

void draw() {
  if (width != prevWidth || height != prevHeight) {
    updatePositions();
    prevWidth = width;
    prevHeight = height;
  }

  if (mode == "DARK") {
    background(0);
  } else {
    background(200);
  }

  stroke(255);

  if (!serialSelected && !oscSelected) {
    return;
  }

  if (mode == "BARS") {
    drawGrid();
    drawBars();
    drawThresholds();
  }

  if (mode == "GRAPHS") {
    drawGrid();
    drawGraphs(filteredGraph, electrodeNumber, filteredColour);
    drawGraphs(baselineGraph, electrodeNumber, baselineColour);
    drawGraphs(touchGraph, electrodeNumber, touchedColour);
    drawGraphs(releaseGraph, electrodeNumber, releasedColour);
    drawStatus(electrodeNumber);
  }

  if (mode == "DARK") {
    drawDarkModeGraphs(filteredGraph, electrodeNumber);
  }

  if ((mode == "GRAPHS" || mode == "BARS") && cursorVisible) {
    updateCursorLabel();
    drawCursor();
  }

  if (helpVisible) {
    fill(200);
    stroke(60);
    strokeWeight(1);
    rectMode(CORNER);

    rect(
      (int)rescaleWidth(graphsLeft + 50) - 10,
      (int)rescaleHeight(44) - 10,
      250,
      92
    );
  }

  if ((millis() > lastMillis + 500) && paused) {
    lastMillis = millis();
    pausedIndicator.setVisible(!pausedIndicator.isVisible());
  }

  if (isResetting) {
    if (millis() - resetStartTime > RESET_TIMEOUT) {
      fullReset();
    } else {
      boolean connected = false;

      try {
        setupSerial();
        inPort.read();
        connected = true;
      } catch (RuntimeException e) {
      }

      if (connected) {
        firstRead = true;
        secondRead = false;
        isResetting = false;
      }
    }
  }
}

@Override void exit() {
  saveSettings();
  super.exit();
}

int JSONGetIntOr(JSONObject o, String key, int notFound) {
  int value = notFound;

  try {
    value = o.getInt(key);
  } catch (RuntimeException e) {
  }

  return value;
}

void readSettings() {
  File settingsFile = new File(dataPath("settings.json"));

  if (!settingsFile.exists()) {
    return;
  }

  JSONObject settings = loadJSONObject(dataPath("settings.json"));

  int windowWidth = JSONGetIntOr(settings, "windowWidth", 1024);
  int windowHeight = JSONGetIntOr(settings, "windowHeight", 600);

  int windowX = JSONGetIntOr(settings, "windowX", -1);
  int windowY = JSONGetIntOr(settings, "windowY", -1);

  displayFrame.setSize(windowWidth, windowHeight);

  if (windowX >= 0 && windowY >= 0) {
    displayFrame.setLocation(new Point(windowX, windowY));
  }
}

void saveSettings() {
  JSONObject settings = new JSONObject();

  settings.setInt("windowWidth", prevWidth);
  settings.setInt("windowHeight", prevHeight);

  settings.setInt("windowX", displayFrame.getX());
  settings.setInt("windowY", displayFrame.getY());

  saveJSONObject(settings, dataPath("settings.json"));
}

void oscEvent(OscMessage oscMessage) {
  if (paused || !oscSelected) {
    return;
  }

  if (firstRead && oscMessage.checkAddrPattern("/diff")) {
    firstRead = false;
  } else {
    if (oscMessage.checkAddrPattern("/touch")) {
      updateArrayOSC(status, oscMessage.arguments());
    } else if (oscMessage.checkAddrPattern("/tths")) {
      updateArrayOSC(touchThresholds, oscMessage.arguments());
    } else if (oscMessage.checkAddrPattern("/rths")) {
      updateArrayOSC(releaseThresholds, oscMessage.arguments());
    } else if (oscMessage.checkAddrPattern("/fdat")) {
      updateArrayOSC(filteredData, oscMessage.arguments());
    } else if (oscMessage.checkAddrPattern("/bval")) {
      updateArrayOSC(baselineVals, oscMessage.arguments());
    } else if (oscMessage.checkAddrPattern("/diff")) {
      updateArrayOSC(diffs, oscMessage.arguments());
      updateGraphs(); // update graphs when we get a DIFF line as this is the last of our dataset
    }
  }
}

void serialEvent(Serial p) {
  if (paused || !serialSelected) {
    return;
  }

  inString = p.readString();
  splitString = splitTokens(inString, ": ");

  if (firstRead && splitString[0].equals("DIFF")) {
    firstRead = false;
    secondRead = true;
  } else {
    if (splitString[0].equals("TOUCH")) {
      updateArraySerial(status);
    } else if (splitString[0].equals("TTHS")) {
      updateArraySerial(touchThresholds);
    } else if (splitString[0].equals("RTHS")) {
      updateArraySerial(releaseThresholds);
    } else if (splitString[0].equals("FDAT")) {
      updateArraySerial(filteredData);
    } else if (splitString[0].equals("BVAL")) {
      updateArraySerial(baselineVals);
    } else if (splitString[0].equals("DIFF")) {
      updateArraySerial(diffs);

      if (secondRead) {
        for (int i = 0; i < numElectrodes; i++) {
          fakeTouchThresholds[i] = touchThresholds[i];
          fakeReleaseThresholds[i] = releaseThresholds[i];
          lastFakeTouchThresholds[i] = touchThresholds[i];
        }
      }
      secondRead = false;

      updateGraphs(); // update graphs when we get a DIFF line as this is the last of our dataset
    }
  }
}

void setupSerial() {
  inPort = new Serial(this, validSerialList[serialNumber], baudRate);
  inPort.bufferUntil(lf);
}

void controlEvent(ControlEvent controlEvent) {
  if (controlEvent.isFrom(cp5.getController("electrodeSel"))) {
    electrodeNumber = (int)controlEvent.getController().getValue();
  } else if (controlEvent.isFrom(cp5.getController("serialSel"))) {
    serialNumber = (int)controlEvent.getController().getValue();

    setupSerial();

    serialSelected = true;
    oscSelected    = false;

    disableStartPrompt();
    enableRunGUI();
    showGraphLabels();
    electrodeSelector.show();
    updatePositions();
  } else if (controlEvent.isFrom(cp5.getController("oscButton"))) {
    serialSelected = false;
    oscSelected    = true;

    disableStartPrompt();
    enableRunGUI();
    showGraphLabels();
    electrodeSelector.show();
    updatePositions();
  } else if (controlEvent.isFrom(cp5.getController("helpButton"))) {
    helpVisible = !helpVisible;

    if (helpVisible) {
      instructions.show();
    } else {
      instructions.hide();
    }
  } else if (controlEvent.isFrom(cp5.getController("resetButton"))) {
    inPort.write("RESET\n");
    inPort.clear();
    inPort.stop();

    delay(100);

    resetStartTime = millis();
    isResetting = true;
  }
}

void mousePressed() {
  if (mode != "BARS") {
    return;
  }

  for (int i = 0; i < numElectrodes; i++) {
    if (mouseX >= rescaleWidth(filteredDataLines[i].left) &&
        mouseX <= rescaleWidth(filteredDataLines[i].right) &&
        mouseY >= rescaleHeight(filteredDataLines[i].top) &&
        mouseY <= rescaleHeight(filteredDataLines[i].bottom)) {
      mouseOverElectrode = i;
      lastClickY = mouseY;
      return;
    }
  }

  mouseOverElectrode = -1; // invalid
}

void mouseDragged() {
  if (mode != "BARS") {
    return;
  }

  if (mouseOverElectrode >= 0 && mouseOverElectrode < numElectrodes) {
    int threshDiff = (mouseY - lastClickY) * 2;

    fakeTouchThresholds[mouseOverElectrode] = lastFakeTouchThresholds[mouseOverElectrode] + threshDiff;
    if (fakeTouchThresholds[mouseOverElectrode] < 2) {
      fakeTouchThresholds[mouseOverElectrode] = 2;
    } else if (fakeTouchThresholds[mouseOverElectrode] > 255) {
      fakeTouchThresholds[mouseOverElectrode] = 255;
    }

    if (baselineVals[mouseOverElectrode] - fakeTouchThresholds[mouseOverElectrode] <= 10) {
      fakeTouchThresholds[mouseOverElectrode] = baselineVals[mouseOverElectrode] - 10;
    }

    fakeReleaseThresholds[mouseOverElectrode] = fakeTouchThresholds[mouseOverElectrode] / 2;
  }
}

void mouseReleased() {
  if (mode != "BARS") {
    return;
  }

  if (mouseOverElectrode >= 0 && mouseOverElectrode < numElectrodes) {
    lastFakeTouchThresholds[mouseOverElectrode] = fakeTouchThresholds[mouseOverElectrode];

    // touch threshold
    inPort.write("STTH:" + mouseOverElectrode + ":" + fakeTouchThresholds[mouseOverElectrode] + "\n");

    // release threshold
    inPort.write("SRTH:" + mouseOverElectrode + ":" + fakeReleaseThresholds[mouseOverElectrode] + "\n");
  }
}

void keyPressed() {
  if (!(serialSelected || oscSelected)) {
    return;
  }

  if (key == CODED) {
    if (keyCode == LEFT) {
      if (electrodeSelector.getValue() > 0) {
        electrodeSelector.setValue((int)electrodeSelector.getValue() - 1);
      }
    } else if (keyCode == RIGHT) {
      if (electrodeSelector.getValue() < numElectrodes - 1) {
        electrodeSelector.setValue((int)electrodeSelector.getValue() + 1);
      }
    }
  } else if (key == 'p' || key == 'P') {
    paused = !paused;
    lastMillis = millis();

    if (paused) {
      pausedIndicator.setVisible(true);
    } else {
      pausedIndicator.setVisible(false);
    }
  } else if (key == 's' || key == 'S') {
    mode = "DARK";

    for (int i = 1; i < numFooterLabels; i++) {
      labels[i + numVerticalDivisions + 1].setVisible(false);
    }

    cursorVisible = false;
    cursorLabel.hide();
    electrodeSelector.hide();
    disableRunGUI();
    hideGraphLabels();
  } else if (key == 'g' || key == 'G') {
    mode = "GRAPHS";
    electrodeSelector.show();
    enableRunGUI();
    showGraphLabels();
  } else if (key == 'b' || key == 'b') {
    mode = "BARS";
    electrodeSelector.hide();
    enableRunGUI();
    hideGraphLabels();
  } else if (key == 'd' || key == 'D') {
    csvDump();
  } else if (key == 'h' || key == 'H') {
    helpVisible = !helpVisible;

    if (helpVisible) {
      instructions.show();
    } else {
      instructions.hide();
    }
  } else if (key == 'c' || key == 'C') {
    cursorVisible = !cursorVisible;

    if (cursorVisible) {
      cursorLabel.show();
    } else {
      cursorLabel.hide();
    }
  }
}

void csvDump() {
  String outFileName;
  PrintWriter outFile;
  int i;
  int j;

  outFileName = "CSV dumps/CSV dump " + nf(year(), 4) + "-" + nf(month(), 2) + "-" + nf(day(), 2) + " at " + nf(hour(), 2) + "." + nf(minute(), 2) + "." + nf(second(), 2) + ".csv";
  outFile = createWriter(outFileName);

  // columns: E0 filtered data, E0 baseline data, E0 touch threshold, E0 release threshold, E1 filtered data...
  for (i = 0; i < numElectrodes; i++) {
    outFile.print("E" + str(i) + " filtered data," + "E" + str(i) + " baseline data," + "E" + str(i) + " touch threshold," + "E" + str(i) + " release threshold");

    if (i == numElectrodes - 1) {
      outFile.println(); // end of line doesn't need any extra commas
    } else {
      outFile.print(","); // add a comma to separate next batch of headers
    }
  }

  int localGraphPtr = globalGraphPtr;
  int numPointsWritten = 0;

  while (numPointsWritten < numGraphPoints) {
    for (i = 0; i < numElectrodes; i++) {
      outFile.print(
        str(filteredGraph[i][localGraphPtr]) + "," +
        str(baselineGraph[i][localGraphPtr]) + "," +
        str(touchGraph[i][localGraphPtr]) + "," +
        str(releaseGraph[i][localGraphPtr])
      );

      if (i == numElectrodes - 1) {
        outFile.println(); // end of line doesn't need any extra commas
      } else {
        outFile.print(","); // add a comma to separate next batch of headers
      }
    }

    if (++localGraphPtr >= numGraphPoints) {
      localGraphPtr = 0;
    }

    numPointsWritten++;
  }

  // flush the changes and close the file
  outFile.flush();
  outFile.close();

  println("CSV snapshot dumped to " + sketchPath(outFileName));
}
