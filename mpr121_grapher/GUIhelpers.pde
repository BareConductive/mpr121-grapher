void customiseSL(ScrollableList sl) {
  // a convenience function to customize a DropdownList
  sl.setBackgroundColor(color(190));
  sl.setItemHeight(20);
  sl.setBarHeight(20);
  sl.getCaptionLabel().set("dropdown");
  sl.setColorBackground(color(60));
  sl.setColorActive(color(255, 128));
  sl.setSize(210,100);
}

void setupLabels(){
  
  labels = new Textlabel[numFooterLabels + numVerticalDivisions + 1];
  String footerLabels[] = {"FILTERED DATA", "BASELINE DATA", "TOUCHED LEVEL", "RELEASED LEVEL", "TOUCH EVENT", "RELEASE EVENT"};
  int footerColours[] = {filteredColour, baselineColour, touchedColour, releasedColour, touchColour, releaseColour};
  
  for(int i=0; i<numVerticalDivisions+1; i++){
    labels[i] = cp5.addTextlabel(String.valueOf(tenBits-(i*tenBits/numVerticalDivisions)))
                    .setText(String.valueOf(tenBits-(i*tenBits/numVerticalDivisions)))
                    .setPosition(graphsLeft,  graphsTop+i*(graphsHeight/numVerticalDivisions)-10)
                    .setColorValue(textColour)
                    ; 
    labels[i].hide();
  } 

  for(int i=0; i<numFooterLabels; i++){
    labels[i+numVerticalDivisions+1] = cp5.addTextlabel(footerLabels[i])
                    .setText(footerLabels[i])
                    .setPosition(graphFooterLeft+200+100*i,  graphFooterTop)
                    .setColorValue(footerColours[i])
                    ; 
    labels[i+numVerticalDivisions+1].hide();
  } 
  
  pausedIndicator = cp5.addTextlabel("pausedIndicator")
                  .setText("PAUSED")
                  .setPosition(965,  graphFooterTop) 
                  .setColorValue(color(255,0,0,200))
                  .setVisible(false);
                  ;    

}

void setupRunGUI(){
  
  electrodeSelector = cp5.addScrollableList("electrodeSel").setPosition(graphsLeft+graphsWidth-296, 75);
  electrodeSelector.hide();
  customiseSL(electrodeSelector);
  electrodeSelector.getCaptionLabel().set("electrode number");
  for (int i=0;i<numElectrodes;i++) {
    electrodeSelector.addItem("electrode "+i, i);
  }
  electrodeSelector.setValue(electrodeNumber); 
  
  instructions = cp5.addTextlabel("pauseInstructions")
                .setText("PRESS P TO PAUSE, PRESS IT AGAIN TO RESUME\nPRESS D TO DUMP DATA\nPRESS S TO SEE JUST FILTERED DATA (SOLO MODE)")
                .setPosition(graphsLeft+graphsWidth-300,40)
                .setColorValue(textColour)
                ;
  instructions.hide();                
}

void setupSerialPrompt(){
  cp5 = new ControlP5(this);
  
  serialPrompt = cp5.addTextlabel("serialPromptLabel")
                  .setText("SELECT THE SERIAL PORT THAT YOUR BARE CONDUCTIVE TOUCH BOARD IS CONNECTED TO SO WE CAN BEGIN:")
                  .setPosition(100, 100)
                  .setColorValue(textColour)
                  ;   
  
  serialSelector = cp5.addScrollableList("serialSel").setPosition(103, 150);
  customiseSL(serialSelector);
  serialSelector.getCaptionLabel().set("serial port");
  for (int i=0;i<serialList.length;i++) {
    serialSelector.addItem(serialList[i], i);
  }
  serialSelector.close();
  
}

void disableSerialPrompt(){

  serialPrompt.hide();
  serialSelector.hide();
  
}

void enableRunGUI(){

  electrodeSelector.show();
  instructions.show();
  
  for(int i=0; i<numFooterLabels + numVerticalDivisions + 1; i++){
    labels[i].show();  
  }
  
}