/***********************************************************************

  MPR121 output grapher / debug plotter for Bare Conductive Touch Board
  
  Code by Stefan Dzisiewski-Smith, April 2013
  
  Based on examples from many others (Tom Igoe, Andreas Schlegel etc.)
  
  -------------------------------------------------------------------
  
  Depends on controlP5 being installed
  
  http://www.sojamo.de/libraries/controlP5/

***********************************************************************/


import processing.serial.*; 
import controlP5.*;

final int baudRate = 57600;
 
final int numElectrodes = 13; // includes proximity electrode 
final int numGraphPoints = 300;
final int tenBits = 1024;

final int graphsLeft = 20;
final int graphsTop = 20;
final int graphsWidth = 984;
final int graphsHeight = 540;
final int numVerticalDivisions = 8;

final int filteredColour = color(255,0,0,200);
final int baselineColour = color(0,0,255,200);
final int touchedColour = color(255,128,0,200);
final int releasedColour = color(0,128,128,200);
final int textColour = color(60);
final int touchColour = color(255,0,255,200);
final int releaseColour = color(255, 255, 255, 200);

final int graphFooterLeft = 20;
final int graphFooterTop = graphsTop + graphsHeight + 20;

final int numFooterLabels = 6;

boolean serialSelected = false;
boolean firstRead = true;
boolean paused = false;

ControlP5 cp5;
DropdownList electrodeSelector, serialSelector;
Textlabel labels[], serialPrompt, pauseInstructions;
 
Serial inPort;        // The serial port
String[] serialList;
String inString;      // Input string from serial port
String[] splitString; // Input string array after splitting 
int lf = 10;          // ASCII linefeed 
int[] filteredData, baselineVals, diffs, touchThresholds, releaseThresholds, status, lastStatus; 
int[][] filteredGraph, baselineGraph, touchGraph, releaseGraph, statusGraph;
int globalGraphPtr = 0;

int electrodeNumber = 0;
int serialNumber = 4;

void setup(){
  size(1024, 600);
  
  setupGraphs();
  
  serialList = Serial.list();
  println(serialList); 
  
  //setupGUI();
  //setupLabels();
  setupSerialPrompt();
}

void draw(){ 
  background(200); 
  stroke(255);
  if(serialSelected){
    drawGrid();
    drawGraphs(filteredGraph,electrodeNumber, filteredColour);
    drawGraphs(baselineGraph,electrodeNumber, baselineColour);
    drawGraphs(touchGraph,electrodeNumber, touchedColour);
    drawGraphs(releaseGraph,electrodeNumber, releasedColour);
    drawStatus(electrodeNumber);
  }
  //drawYlabels();
  //drawGraphFooter();
}


void serialEvent(Serial p) {
 
  if(serialSelected && !paused){ 
  
    int[] dataToUpdate;
    
    inString = p.readString(); 
    splitString = splitTokens(inString, ": ");
    
    if(firstRead && splitString[0].equals("DIFF")){
      firstRead = false;
    } else {
      if(splitString[0].equals("TOUCH")){
        updateArray(status); 
      } else if(splitString[0].equals("TTHS")){
        updateArray(touchThresholds); 
      } else if(splitString[0].equals("RTHS")){
        updateArray(releaseThresholds);
      } else if(splitString[0].equals("FDAT")){
        updateArray(filteredData); 
      } else if(splitString[0].equals("BVAL")){
        updateArray(baselineVals);
      } else if(splitString[0].equals("DIFF")){
        updateArray(diffs);
        updateGraphs(); // update graphs when we get a DIFF line
                        // as this is the last of our dataset
      }
    }
  }
} 

void controlEvent(ControlEvent theEvent) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.

  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    //println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
    if(theEvent.getGroup().getName().contains("electrodeSel")){
      electrodeNumber = (int)theEvent.getGroup().getValue();
    } else if(theEvent.getGroup().getName().contains("serialSel")) {
      serialNumber = (int)theEvent.getGroup().getValue();
      inPort = new Serial(this, Serial.list()[serialNumber], baudRate);
      inPort.bufferUntil(lf);
      
      disableSerialPrompt();
      setupRunGUI();
      setupLabels();
      serialSelected = true;
      //inPort.stop();
      //inPort = new Serial(this, Serial.list()[serialNumber], baudRate);   
    }
  } 
  else if (theEvent.isController()) {
    //println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());
  }
}

void keyPressed() {
  if (key == 'p' || key == 'P') {
    paused = !paused;
  }
}
