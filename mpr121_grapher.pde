import processing.serial.*; 
import controlP5.*;
 
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
final int textColour = color(100);
final int touchColour = color(255,0,255,200);
final int releaseColour = color(255, 255, 255, 200);

final int graphFooterLeft = 20;
final int graphFooterTop = graphsTop + graphsHeight + 20;

ControlP5 cp5;
DropdownList electrodeSelector, serialSelector;
 
Serial inPort;        // The serial port
String[] serialList;
String inString;      // Input string from serial port
String[] splitString; // Input string array after splitting 
int lf = 10;          // ASCII linefeed 
int[] filteredData, baselineVals, diffs, touchThresholds, releaseThresholds, status, lastStatus; 
int[][] filteredGraph, baselineGraph, touchGraph, releaseGraph, statusGraph;
int globalGraphPtr = 0;
boolean firstRead = true;

int electrodeNumber = 0;
int serialNumber = 4;

void setup(){
  size(1024, 600);
  
  setupGraphs();
  
  serialList = Serial.list();
  println(serialList);
  inPort = new Serial(this, Serial.list()[serialNumber], 57600);
  inPort.bufferUntil(lf); 
  
  setupGUI();
  
}

void draw(){ 
  background(200); 
  stroke(255);
  drawGrid();
  drawGraphs(filteredGraph,electrodeNumber, filteredColour);
  drawGraphs(baselineGraph,electrodeNumber, baselineColour);
  drawGraphs(touchGraph,electrodeNumber, touchedColour);
  drawGraphs(releaseGraph,electrodeNumber, releasedColour);
  drawStatus(electrodeNumber);
  drawYlabels();
  drawGraphFooter();
}


void serialEvent(Serial p) { 
  
  int[] dataToUpdate;
  
  inString = p.readString(); 
  splitString = splitTokens(inString, ":,");
  
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

void controlEvent(ControlEvent theEvent) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.

  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
    if(theEvent.getGroup().getName().contains("electrodeSel")){
      electrodeNumber = (int)theEvent.getGroup().getValue();
    } else if(theEvent.getGroup().getName().contains("serialSel")) {
      serialNumber = (int)theEvent.getGroup().getValue();
      //inPort.stop();
      //inPort = new Serial(this, Serial.list()[serialNumber], 57600);   
    }
  } 
  else if (theEvent.isController()) {
    println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());
  }
}


void customiseDL(DropdownList ddl) {
  // a convenience function to customize a DropdownList
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(20);
  ddl.setBarHeight(15);
  ddl.captionLabel().set("dropdown");
  ddl.captionLabel().style().marginTop = 3;
  ddl.captionLabel().style().marginLeft = 3;
  ddl.valueLabel().style().marginTop = 3;
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255, 128));
  ddl.setWidth(200);
}

void setupGUI(){
  cp5 = new ControlP5(this);

  serialSelector = cp5.addDropdownList("serialSel").setPosition(graphsLeft+graphsWidth-200, 75);
  customiseDL(serialSelector);
  serialSelector.captionLabel().set("serial port");
  for (int i=0;i<serialList.length;i++) {
    serialSelector.addItem(serialList[i], i);
  }
  serialSelector.setIndex(serialNumber);
  
  electrodeSelector = cp5.addDropdownList("electrodeSel").setPosition(graphsLeft+graphsWidth-200, 50);
  customiseDL(electrodeSelector);
  electrodeSelector.captionLabel().set("electrode number");
  for (int i=0;i<numElectrodes;i++) {
    electrodeSelector.addItem("electrode "+i, i);
  }
  electrodeSelector.setIndex(electrodeNumber);  
}
