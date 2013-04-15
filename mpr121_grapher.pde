import processing.serial.*; 
 
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

final int graphFooterLeft = 20;
final int graphFooterTop = graphsTop + graphsHeight + 20;


 
Serial inPort;        // The serial port
String inString;      // Input string from serial port
String[] splitString; // Input string array after splitting 
int lf = 10;          // ASCII linefeed 
int[] filteredData, baselineVals, diffs, touchThresholds, releaseThresholds; 
int[][] filteredGraph, baselineGraph, touchGraph, releaseGraph;
int globalGraphPtr = 0;
boolean firstRead = true;

int electrodeNumber = 5;

void setup(){
  size(1024, 600);
  
  filteredData = new int[numElectrodes];
  baselineVals = new int[numElectrodes];
  diffs = new int[numElectrodes];
  touchThresholds = new int[numElectrodes];
  releaseThresholds = new int[numElectrodes];
  
  filteredGraph = new int[numElectrodes][numGraphPoints];
  baselineGraph = new int[numElectrodes][numGraphPoints];
  touchGraph =    new int[numElectrodes][numGraphPoints];
  releaseGraph =  new int[numElectrodes][numGraphPoints];
  
  println(Serial.list());
  inPort = new Serial(this, Serial.list()[4], 57600); 
  inPort.bufferUntil(lf); 
}

void draw(){ 
  background(200); 
  stroke(255);
  drawGrid();
  drawGraphs(filteredGraph,electrodeNumber, filteredColour);
  drawGraphs(baselineGraph,electrodeNumber, baselineColour);
  drawGraphs(touchGraph,electrodeNumber, touchedColour);
  drawGraphs(releaseGraph,electrodeNumber, releasedColour);
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
    if(splitString[0].equals("TTHS")){
      updateArray(touchThresholds);
      //println("TTHS"); 
    } else if(splitString[0].equals("RTHS")){
      updateArray(releaseThresholds);
      //println("RTHS"); 
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

void drawText(int[] arrayToDraw){
  fill(0);
  for(int i=0; i<arrayToDraw.length; i++){
    text(arrayToDraw[i], 20, 50+20*i);
  }    
}

void drawLevels(int[] arrayToDraw){
  for(int i=0; i<arrayToDraw.length; i++){
    rect(40+75*i, 295-arrayToDraw[i], 50, 10);
  }   
}

void updateArray(int[] array){
  if(array != null){
    for(int i=0; i<min(array.length, splitString.length-1); i++){
      try{
        array[i] = Integer.parseInt(trim(splitString[i+1]));
      } catch (NumberFormatException e){
        array[i] = 0; 
      } 
      //println(array[i]); 
    }
  }  else {
    //println ("null array");  
  }
}

void updateGraphs(){
  
  //println("updateGraphs");
  
  for(int i=0; i<numElectrodes; i++){
    filteredGraph[i][globalGraphPtr] = filteredData[i];
    baselineGraph[i][globalGraphPtr] = baselineVals[i]; 
    touchGraph[i][globalGraphPtr] = baselineVals[i] - touchThresholds[i];
    releaseGraph[i][globalGraphPtr] = baselineVals[i] - releaseThresholds[i]; 
  }
  if(++globalGraphPtr >= numGraphPoints) globalGraphPtr = 0;
  
}

void drawGraphs(int[][] graph, int electrode, int graphColour){
  int scratchColor =g.strokeColor;
  float scratchWeight = g.strokeWeight;
  stroke(graphColour);
  strokeWeight(2);
  
  int localGraphPtr = globalGraphPtr;
  int numPointsDrawn = 0;
  
  int lastX = -1;
  int lastY = -1;
  int thisX = -1;
  int thisY = -1;
   
  while(numPointsDrawn < numGraphPoints){
    thisX = (int)(graphsLeft+(numPointsDrawn*graphsWidth/numGraphPoints));
    thisY = (int)graphsTop+ (int)(graphsHeight*(1-((float)graph[electrode][localGraphPtr] / (float)tenBits)));
  
    if(lastX>=0 && lastY>=0){
      line(lastX, lastY, thisX, thisY);
    }  
    
    lastX = thisX;
    lastY = thisY;
    if(++localGraphPtr>=numGraphPoints) localGraphPtr = 0;
    numPointsDrawn++;
  }
  
  stroke(scratchColor);
  strokeWeight(scratchWeight);
   
}

void drawGrid(){
  int scratchColor =g.strokeColor;
  float scratchWeight = g.strokeWeight;

  stroke(textColour);
  strokeWeight(1);

  for(int i=0; i<=numVerticalDivisions; i++){
    line(graphsLeft, graphsTop+i*(graphsHeight/numVerticalDivisions), graphsLeft+graphsWidth, graphsTop+i*(graphsHeight/numVerticalDivisions));   
  }
  
  stroke(scratchColor);
  strokeWeight(scratchWeight);
}

void drawYlabels(){
  int scratchFillColor = g.fillColor;
  
  fill(textColour);
  
  for(int i=0; i<=numVerticalDivisions; i++){
    text((numVerticalDivisions-i)*tenBits/numVerticalDivisions, graphsLeft,  graphsTop+i*(graphsHeight/numVerticalDivisions)-3); 
  }
  
  fill(scratchFillColor);
}

void drawGraphFooter(){
  int scratchFillColor = g.fillColor;

  fill(textColour);
  text("electrode " + electrodeNumber, graphFooterLeft, graphFooterTop);
 
  fill(filteredColour);
  text("filtered data", graphFooterLeft+100, graphFooterTop); 
  
  fill(baselineColour);
  text("baseline data", graphFooterLeft+200, graphFooterTop);  
  
  fill(touchedColour);
  text("touched level", graphFooterLeft+300, graphFooterTop);  
  
  fill(releasedColour);
  text("released level", graphFooterLeft+400, graphFooterTop);  
  
  fill(scratchFillColor);
}
