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
  } 

  for(int i=0; i<numFooterLabels; i++){
    labels[i+numVerticalDivisions+1] = cp5.addTextlabel(footerLabels[i])
                    .setText(footerLabels[i])
                    .setPosition(graphFooterLeft+200+100*i,  graphFooterTop)
                    .setColorValue(footerColours[i])
                    ; 
  } 

}

void setupRunGUI(){
  
  electrodeSelector = cp5.addDropdownList("electrodeSel").setPosition(graphsLeft+graphsWidth-300, 75);
  customiseDL(electrodeSelector);
  electrodeSelector.captionLabel().set("electrode number");
  for (int i=0;i<numElectrodes;i++) {
    electrodeSelector.addItem("electrode "+i, i);
  }
  electrodeSelector.setIndex(electrodeNumber);  
  
  pauseInstructions = cp5.addTextlabel("pauseInstructions")
                .setText("PRESS P TO PAUSE, PRESS IT AGAIN TO RESUME")
                .setPosition(graphsLeft+graphsWidth-300,40)
                .setColorValue(textColour)
                ;   
}

void setupSerialPrompt(){
  cp5 = new ControlP5(this);
  
  serialPrompt = cp5.addTextlabel("serialPromptLabel")
                  .setText("SELECT THE SERIAL PORT THAT YOUR BARE CONDUCTIVE TOUCH BOARD IS CONNECTED TO SO WE CAN BEGIN:")
                  .setPosition(100,  100)
                  .setColorValue(textColour)
                  ;   
  
  serialSelector = cp5.addDropdownList("serialSel").setPosition(100, 150);
  customiseDL(serialSelector);
  serialSelector.captionLabel().set("serial port");
  for (int i=0;i<serialList.length;i++) {
    serialSelector.addItem(serialList[i], i);
  }
  //serialSelector.setIndex(serialNumber);
  
}

void disableSerialPrompt(){

  serialPrompt.setVisible(false);
  serialSelector.setVisible(false);
  
}
