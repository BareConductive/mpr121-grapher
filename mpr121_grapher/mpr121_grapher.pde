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

 This work is licensed under a Creative Commons Attribution-ShareAlike 3.0
 Unported License (CC BY-SA 3.0) http://creativecommons.org/licenses/by-sa/3.0/

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

*******************************************************************************/

import processing.serial.*;
import controlP5.*;
import oscP5.*;
import netP5.*;

final int baudRate = 57600;

final int numElectrodes  = 12;
final int numGraphPoints = 300;
final int tenBits        = 1024;

final int graphsLeft           = 20;
final int graphsTop            = 20;
final int graphsWidth          = 984;
final int graphsHeight         = 540;
final int numVerticalDivisions = 8;

final int filteredColour = color(255, 0,   0,   200);
final int baselineColour = color(0,   0,   255, 200);
final int touchedColour  = color(255, 128, 0,   200);
final int releasedColour = color(0,   128, 128, 200);
final int textColour     = color(60);
final int touchColour    = color(255, 0,   255, 200);
final int releaseColour  = color(255, 255, 255, 200);

final int graphFooterLeft = 20;
final int graphFooterTop  = graphsTop + graphsHeight + 20;

final int numFooterLabels = 6;

boolean serialSelected = false;
boolean oscSelected    = false;
boolean firstRead      = true;
boolean paused         = false;
boolean soloMode       = false;

ControlP5 cp5;
ScrollableList electrodeSelector, serialSelector;
Textlabel labels[], startPrompt, instructions, pausedIndicator;
Button oscButton;

OscP5 oscP5;

Serial inPort;        // the serial port
String[] serialList;
String inString;      // input string from serial port
String[] splitString; // input string array after splitting
int lf = 10;          // ASCII linefeed

int[] filteredData, baselineVals, diffs, touchThresholds, releaseThresholds, status, lastStatus;
int[][] filteredGraph, baselineGraph, touchGraph, releaseGraph, statusGraph;

int globalGraphPtr  = 0;
int electrodeNumber = 0;
int serialNumber    = 4;
int lastMillis      = 0;

void setup() {
  size(1024, 600);

  // init cp5
  cp5 = new ControlP5(this);

  // setup OSC receiver on port 3000
  oscP5 = new OscP5(this, 3000);

  // init serial
  serialList = Serial.list();

  setupGraphs();

  setupStartPrompt();
  setupRunGUI();
  setupLabels();
}

void draw() {
  background(200);
  stroke(255);

  if (!serialSelected && !oscSelected) {
    return;
  }

  drawGrid();
  drawGraphs(filteredGraph,electrodeNumber, filteredColour);

  if (!soloMode) {
    drawGraphs(baselineGraph,electrodeNumber, baselineColour);
    drawGraphs(touchGraph,electrodeNumber, touchedColour);
    drawGraphs(releaseGraph,electrodeNumber, releasedColour);
    drawStatus(electrodeNumber);
  }

  if ((millis() > lastMillis + 500) && paused) {
    lastMillis = millis();
    pausedIndicator.setVisible(!pausedIndicator.isVisible());
  }
}

void oscEvent(OscMessage oscMessage) {
  if (paused || !oscSelected) {
    return;
  }

  if (firstRead && oscMessage.checkAddrPattern("/diff")) {
    firstRead = false;
  }
  else {
    if (oscMessage.checkAddrPattern("/touch")) {
      updateArrayOSC(status, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/tths")) {
      updateArrayOSC(touchThresholds, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/rths")) {
      updateArrayOSC(releaseThresholds, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/fdat")) {
      updateArrayOSC(filteredData, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/bval")) {
      updateArrayOSC(baselineVals, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/diff")) {
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
  }
  else {
    if (splitString[0].equals("TOUCH")) {
      updateArraySerial(status);
    }
    else if(splitString[0].equals("TTHS")) {
      updateArraySerial(touchThresholds);
    }
    else if(splitString[0].equals("RTHS")) {
      updateArraySerial(releaseThresholds);
    }
    else if(splitString[0].equals("FDAT")) {
      updateArraySerial(filteredData);
    }
    else if(splitString[0].equals("BVAL")) {
      updateArraySerial(baselineVals);
    }
    else if(splitString[0].equals("DIFF")) {
      updateArraySerial(diffs);
      updateGraphs(); // update graphs when we get a DIFF line as this is the last of our dataset
    }
  }
}

void controlEvent(ControlEvent controlEvent) {
  if (controlEvent.isFrom(cp5.getController("electrodeSel"))) {
    electrodeNumber = (int)controlEvent.getController().getValue();
  }
  else if (controlEvent.isFrom(cp5.getController("serialSel"))) {
    serialNumber = (int)controlEvent.getController().getValue();
    inPort = new Serial(this, Serial.list()[serialNumber], baudRate);
    inPort.bufferUntil(lf);

    disableStartPrompt();
    enableRunGUI();

    serialSelected = true;
    oscSelected    = false;
  }
  else if (controlEvent.isFrom(cp5.getController("oscButton"))) {
    disableStartPrompt();
    enableRunGUI();

    serialSelected = false;
    oscSelected    = true;
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      if (electrodeSelector.getValue() > 0) {
        electrodeSelector.setValue((int)electrodeSelector.getValue()-1);
      }
    }
    else if (keyCode == RIGHT) {
      if (electrodeSelector.getValue() < numElectrodes - 1) {
        electrodeSelector.setValue((int)electrodeSelector.getValue()+1);
      }
    }
  }
  else if (key == 'p' || key == 'P') {
    paused = !paused;
    lastMillis = millis();

    if (paused) {
      pausedIndicator.setVisible(true);
    }
    else {
      pausedIndicator.setVisible(false);
    }
  }
  else if (key == 's' || key == 'S') {
    soloMode = !soloMode;

    for (int i = 1; i < numFooterLabels; i++) {
      if (soloMode) {
        labels[i + numVerticalDivisions + 1].setVisible(false);
      }
      else {
        labels[i + numVerticalDivisions + 1].setVisible(true);
      }
    }
  }
  else if (key == 'd' || key == 'D') {
    csvDump();
  }
}

void csvDump() {
  String outFileName;
  PrintWriter outFile;
  int i;
  int j;

  outFileName = "CSV dumps/CSV dump " + nf(year(),4) + "-" + nf(month(),2) + "-" + nf(day(),2) + " at " + nf(hour(),2) + "." + nf(minute(),2) + "." + nf(second(),2) + ".csv";
  outFile = createWriter(outFileName);

  // columns: E0 filtered data, E0 baseline data, E0 touch threshold, E0 release threshold, E1 filtered data...
  for (i = 0; i < numElectrodes; i++) {
    outFile.print("E" + str(i) + " filtered data," + "E" + str(i) + " baseline data," + "E" + str(i) + " touch threshold," + "E" + str(i) + " release threshold");

    if (i == numElectrodes - 1) {
      outFile.println(); // end of line doesn't need any extra commas
    }
    else {
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
      }
      else {
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