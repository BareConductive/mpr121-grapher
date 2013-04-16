void setupGraphs(){
  filteredData = new int[numElectrodes];
  baselineVals = new int[numElectrodes];
  diffs = new int[numElectrodes];
  touchThresholds = new int[numElectrodes];
  releaseThresholds = new int[numElectrodes];
  status = new int[numElectrodes];
  lastStatus = new int[numElectrodes];
  
  for(int i=0; i<numElectrodes; i++){
    status[i] = 128; // 128 is an unused value from the Arduino input
    lastStatus[i] = 128;  
  }
  
  filteredGraph = new int[numElectrodes][numGraphPoints];
  baselineGraph = new int[numElectrodes][numGraphPoints];
  touchGraph =    new int[numElectrodes][numGraphPoints];
  releaseGraph =  new int[numElectrodes][numGraphPoints];
  statusGraph =  new int[numElectrodes][numGraphPoints];  
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
  
  int lastGraphPtr = globalGraphPtr-1;
  if(lastGraphPtr < 0) lastGraphPtr = numGraphPoints-1;
  
  for(int i=0; i<numElectrodes; i++){
    filteredGraph[i][globalGraphPtr] = filteredData[i];
    baselineGraph[i][globalGraphPtr] = baselineVals[i]; 
    touchGraph[i][globalGraphPtr] = baselineVals[i] - touchThresholds[i];
    releaseGraph[i][globalGraphPtr] = baselineVals[i] - releaseThresholds[i]; 
    if(lastStatus[i]==0 && status[i]==0xFF){
      // touched
      statusGraph[i][globalGraphPtr] = 1;    
    } else if(lastStatus[i]==0xFF && status[i]==0x00){
      // released
     statusGraph[i][globalGraphPtr] = -1;  
    } else {
     statusGraph[i][globalGraphPtr] = 0;  
    }
  }
  
  for(int i=0; i<numElectrodes; i++){
    lastStatus[i] = status[i];
  }
  
  if(++globalGraphPtr >= numGraphPoints) globalGraphPtr = 0;
  
}

void drawGraphs(int[][] graph, int electrode, int graphColour){
  int scratchColor =g.strokeColor;
  int scratchFill = g.fillColor;
  float scratchWeight = g.strokeWeight;
  stroke(graphColour);
  strokeWeight(2);
  fill(0,0,0,0);
  
  int localGraphPtr = globalGraphPtr;
  int numPointsDrawn = 0;
  
  int thisX = -1;
  int thisY = -1;
  
  beginShape();
   
  while(numPointsDrawn < numGraphPoints){
    thisX = (int)(graphsLeft+(numPointsDrawn*graphsWidth/numGraphPoints));
    thisY = (int)graphsTop+ (int)(graphsHeight*(1-((float)graph[electrode][localGraphPtr] / (float)tenBits)));
    
    vertex(thisX, thisY);
 
    if(++localGraphPtr>=numGraphPoints) localGraphPtr = 0;
    numPointsDrawn++;
  }
  
  endShape();
  
  stroke(scratchColor);
  strokeWeight(scratchWeight);
  fill(scratchFill);
   
}

void drawLevels(int[] arrayToDraw){
  for(int i=0; i<arrayToDraw.length; i++){
    rect(40+75*i, 295-arrayToDraw[i], 50, 10);
  }   
}

void drawStatus(int electrode){
  int scratchColor =g.strokeColor;
  float scratchWeight = g.strokeWeight;
  strokeWeight(2);
  
  int thisX;
  
  int localGraphPtr = globalGraphPtr;
  int numPointsDrawn = 0;
   
  while(numPointsDrawn < numGraphPoints){
    thisX = (int)(graphsLeft+(numPointsDrawn*graphsWidth/numGraphPoints));
  
    if(statusGraph[electrode][localGraphPtr] == 1){
      //println("beep");
      stroke(touchColour);
      line(thisX, graphsTop, thisX, graphsTop+graphsHeight);  
    } else if(statusGraph[electrode][localGraphPtr] == -1){
      //println("beep");
      stroke(releaseColour);
      line(thisX, graphsTop, thisX, graphsTop+graphsHeight);  
    }

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

//  fill(textColour);
//  text("electrode " + electrodeNumber, graphFooterLeft, graphFooterTop);
 
  fill(filteredColour);
  text("filtered data", graphFooterLeft+200, graphFooterTop); 
  
  fill(baselineColour);
  text("baseline data", graphFooterLeft+300, graphFooterTop);  
  
  fill(touchedColour);
  text("touched level", graphFooterLeft+400, graphFooterTop);  
  
  fill(releasedColour);
  text("released level", graphFooterLeft+500, graphFooterTop);  
  
  fill(touchColour);
  text("touch event", graphFooterLeft+600, graphFooterTop); 
  
  fill(releaseColour);
  text("release event", graphFooterLeft+700, graphFooterTop); 
  
  fill(scratchFillColor);
}

void drawText(int[] arrayToDraw){
  fill(0);
  for(int i=0; i<arrayToDraw.length; i++){
    text(arrayToDraw[i], 20, 50+20*i);
  }    
}
