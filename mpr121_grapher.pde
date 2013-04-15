import processing.serial.*; 
 
final int numElectrodes = 13; // includes proximity electrode 
final int numGraphPoints = 200;
final int tenBits = 1024;
 
Serial inPort;        // The serial port
String inString;      // Input string from serial port
String[] splitString; // Input string array after splitting 
int lf = 10;          // ASCII linefeed 
int[] filteredData, baselineVals, diffs, touchThresholds, releaseThresholds; 
int[][] filteredGraph, baselineGraph, touchGraph, releaseGraph;
int globalGraphPtr = 0;

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
  //text("received: " + inString, 10,50);
//  if(splitString != null){
//    for(int i=0; i<splitString.length; i++){
//      text(splitString[i], 10, 50+i*32);
//    }  
//  }
  
//  if(diffs != null){
//    for(int i=0; i<diffs.length; i++){
//      text(diffs[i], 10, 50+i*32);
//    }  
//  }  
  drawGraphs(filteredGraph,0,20,20,984,540, color(255,0,0,200));
  drawGraphs(baselineGraph,0,20,20,984,540, color(0,0,255,200));
  drawGraphs(touchGraph,0,20,20,984,540, color(255,255,0,200));
  drawGraphs(releaseGraph,0,20,20,984,540, color(0,255,0,200));
  //drawGraphs(filteredGraph,0,0,0,0,0);
  drawLevels(diffs);
  //line(0,0,100,100);
  drawText(touchThresholds);
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

void serialEvent(Serial p) { 
  
  int[] dataToUpdate;
  
  inString = p.readString(); 
  splitString = splitTokens(inString, ":,");
  
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
                    // as this is the last of the trio
  } else {
    println("didn't find tag");  
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

void drawGraphs(int[][] graph, int electrode, float left, float top, float wth, float hgt, int graphColour){
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
  
  //if(--localGraphPtr < 0) localGraphPtr = numGraphPoints - 1;
   
  while(numPointsDrawn < numGraphPoints){
    thisX = (int)(left+(numPointsDrawn*wth/numGraphPoints));
    //thisX = (int)(left+numPointsDrawn);
    //println(thisX);
    //thisY = 500-(array[0][localGraphPtr]/2);
    thisY = (int)top+ (int)(hgt*(1-((float)graph[electrode][localGraphPtr] / (float)tenBits)));
    //println(thisY);
  
    if(lastX>=0 && lastY>=0){
      line(lastX, lastY, thisX, thisY);
//      print(lastX);
//      print(",");
//      print(lastY);
//      print("->");
//      print(thisX);
//      print(",");
//      println(thisY);
      //println("beep");
    }  
    lastX = thisX;
    lastY = thisY;
    if(++localGraphPtr>=numGraphPoints) localGraphPtr = 0;
    numPointsDrawn++;
    //println(numPointsDrawn);
  }
  
  stroke(scratchColor);
  strokeWeight(scratchWeight);
   
}

