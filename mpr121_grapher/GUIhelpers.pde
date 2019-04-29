/*******************************************************************************

 Bare Conductive MPR121 output grapher / debug plotter for TouchBoard and Pi Cap
 -------------------------------------------------------------------------------

 GUIhelpers.pde - helper functions for mpr121_grapher.pde

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

void customiseSL(ScrollableList sl) {
  // a convenience function to customize a DropdownList
  sl.setBackgroundColor(color(190));
  sl.setItemHeight(20);
  sl.setBarHeight(20);
  sl.getCaptionLabel().set("dropdown");
  sl.setColorBackground(color(60));
  sl.setColorActive(color(255, 128));
  sl.setSize(210, 100);
}

void setupLabels() {
  labels = new Textlabel[numFooterLabels + numVerticalDivisions + 1];

  String footerLabels[] = { "FILTERED DATA", "BASELINE DATA", "TOUCHED LEVEL", "RELEASED LEVEL", "TOUCH EVENT", "RELEASE EVENT" };
  int footerColours[]   = { filteredColour, baselineColour, touchedColour, releasedColour, touchColourGraph, releaseColour };

  for (int i = 0; i < numVerticalDivisions + 1; i++) {
    labels[i] = cp5
                .addTextlabel(String.valueOf(tenBits - (i * tenBits / numVerticalDivisions)))
                .setText(String.valueOf(tenBits - (i * tenBits / numVerticalDivisions)))
                .setColorValue(textColour);

    labels[i].hide();
  }

  for (int i = 0; i < numFooterLabels; i++) {
    labels[i + numVerticalDivisions + 1] = cp5
                                           .addTextlabel(footerLabels[i])
                                           .setText(footerLabels[i])
                                           .setColorValue(footerColours[i]);

    labels[i + numVerticalDivisions + 1].hide();
  }

  pausedIndicator = cp5
                    .addTextlabel("pausedIndicator")
                    .setText("PAUSED")
                    .setColorValue(color(255, 0, 0, 200))
                    .setVisible(false);

  cursorLabel = cp5
                .addTextlabel("")
                .setColorValue(textColour)
                .setVisible(false);
}

void setupRunGUI() {
  electrodeSelector = cp5.addScrollableList("electrodeSel");
  electrodeSelector.hide();
  customiseSL(electrodeSelector);
  electrodeSelector.getCaptionLabel().set("electrode number");
  for (int i = 0; i < numElectrodes; i++) {
    electrodeSelector.addItem("electrode " + i, i);
  }
  electrodeSelector.setValue(electrodeNumber);

  instructions = cp5
                 .addTextlabel("pauseInstructions")
                 .setText("PRESS H TO TOGGLE HELP\nPRESS P TO TOGGLE PAUSE\nPRESS C TO TOGGLE CURSOR\nRPRESS D TO DUMP DATA\n\nPRESS S TO SEE JUST FILTERED DATA (SOLO MODE)\nPRESS B TO SEE BAR GRAPH\nPRESS G TO GET BACK TO GRAPHS")
                 .setColorValue(textColour);

  instructions.hide();

  helpButton = cp5
               .addButton("helpButton")
               .setCaptionLabel("HELP")
               .setColorBackground(color(60))
               .setSize(100, 20);

  helpButton.hide();

  resetButton = cp5
                .addButton("resetButton")
                .setCaptionLabel("RESET")
                .setColorBackground(color(60))
                .setSize(100, 20);

  resetButton.hide();
}

void setupStartPrompt() {
  startPrompt = cp5
                .addTextlabel("startPromptLabel")
                .setText("SELECT THE SERIAL PORT THAT YOUR BARE CONDUCTIVE TOUCH BOARD IS CONNECTED TO, OR CHOOSE OSC SO WE CAN BEGIN:")
                .setColorValue(textColour) ;

  serialSelector = cp5.addScrollableList("serialSel");
  customiseSL(serialSelector);
  serialSelector.getCaptionLabel().set("serial port");

  for (int i = 0; i < validSerialList.length; i++) {
    serialSelector.addItem(validSerialList[i], i);
  }

  serialSelector.close();

  oscButton = cp5
              .addButton("oscButton")
              .setCaptionLabel("OSC")
              .setColorBackground(color(60))
              .setSize(120, 20);
}

void updateCursorLabel() {
  float value = tenBits - (((mouseY - rescaleHeight(graphsTop)) / rescaleHeight(graphsHeight)) * tenBits);
  value = constrain(value, 0, 1024);

  float posY = constrain(mouseY, rescaleHeight(graphsTop), rescaleHeight(graphsTop + graphsHeight));

  cursorLabel
  .setText(String.valueOf(round(value)))
  .setPosition(
    (int)rescaleWidth(graphsLeft + graphsWidth) - 28,
    posY - 5
  );
}

void enableStartPrompt() {
  startPrompt.show();
  serialSelector.show();
  oscButton.show();
}

void disableStartPrompt() {
  startPrompt.hide();
  serialSelector.hide();
  oscButton.hide();
}

void enableRunGUI() {
  helpButton.show();

  if (serialSelected) {
    resetButton.show();
  }

  for (int i = 0; i < numVerticalDivisions + 1; i++) {
    labels[i].show();
  }
}

void disableRunGUI() {
  helpButton.hide();
  resetButton.hide();

  for (int i = 0; i < numVerticalDivisions + 1; i++) {
    labels[i].hide();
  }

}

void showGraphLabels() {
  for (int i = 0; i < numFooterLabels; i++) {
    labels[i + numVerticalDivisions + 1].show();
  }
}

void hideGraphLabels() {
  for (int i = 0; i < numFooterLabels; i++) {
    labels[i + numVerticalDivisions + 1].hide();
  }
}

void updatePositions() {
  for (int i = 0; i < numVerticalDivisions + 1; i++) {
    labels[i].setPosition(
      (int)rescaleWidth(graphsLeft),
      (int)rescaleHeight(graphsTop + i * (graphsHeight / numVerticalDivisions) - 10));
  }

  for (int i = 0; i < numFooterLabels; i++) {
    labels[i + numVerticalDivisions + 1].setPosition(
      (int)rescaleWidth(graphFooterLeft + 200 + 100 * i),
      (int)rescaleHeight(graphFooterTop));
  }

  electrodeSelector.setPosition((int)rescaleWidth(graphsLeft) + (serialSelected ? 240 : 120), (int)rescaleHeight(10));
  helpButton.setPosition((int)rescaleWidth(graphsLeft), (int)rescaleHeight(10));
  instructions.setPosition((int)rescaleWidth(graphsLeft + 50), (int)rescaleHeight(44));
  oscButton.setPosition((int)rescaleWidth(530), (int)rescaleHeight(150));
  pausedIndicator.setPosition((int)rescaleWidth(965), (int)rescaleHeight(graphFooterTop));
  resetButton.setPosition((int)rescaleWidth(graphsLeft) + 120, (int)rescaleHeight(10));
  serialSelector.setPosition((int)rescaleWidth(103), (int)rescaleHeight(150));
  startPrompt.setPosition((int)rescaleWidth(100), (int)rescaleHeight(100));

  // update cp5 graphics binding so event handlers can realign their picking coordinates
  cp5.setGraphics(this, 0, 0);
}

