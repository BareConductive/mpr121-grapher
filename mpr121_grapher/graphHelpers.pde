/*******************************************************************************

 Bare Conductive MPR121 output grapher / debug plotter for TouchBoard and Pi Cap
 -------------------------------------------------------------------------------

 graphHelpers.pde - helper functions for mpr121_grapher.pde

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

float rescaleWidth(float w) {
  return map(w, 0, DEFAULT_WIDTH, 0, width);
}

float rescaleHeight(float h) {
  return map(h, 0, DEFAULT_HEIGHT, 0, height);
}

void setupGraphs() {
  filteredData              = new int[numElectrodes];
  baselineVals              = new int[numElectrodes];
  diffs                     = new int[numElectrodes];
  touchThresholds           = new int[numElectrodes];
  releaseThresholds         = new int[numElectrodes];
  fakeTouchThresholds       = new int[numElectrodes];
  fakeReleaseThresholds     = new int[numElectrodes];
  lastFakeTouchThresholds   = new int[numElectrodes];
  status                    = new int[numElectrodes];
  lastStatus                = new int[numElectrodes];
  filteredDataLines         = new Line[numElectrodes];
  touchLines                = new Line[numElectrodes];
  releaseLines              = new Line[numElectrodes];

  for (int i = 0; i < numElectrodes; i++) {
    status[i] = 128; // 128 is an unused value from the Arduino input
    lastStatus[i] = 128;
    filteredDataLines[i] = new Line();
    touchLines[i] = new Line();
    releaseLines[i] = new Line();
  }

  filteredGraph = new int[numElectrodes][numGraphPoints];
  baselineGraph = new int[numElectrodes][numGraphPoints];
  touchGraph    = new int[numElectrodes][numGraphPoints];
  releaseGraph  = new int[numElectrodes][numGraphPoints];
  statusGraph   = new int[numElectrodes][numGraphPoints];
}

void updateArrayOSC(int[] array, Object[] data) {
  if (array == null || data == null) {
    return;
  }

  for (int i = 0; i < min(array.length, data.length); i++) {
    array[i] = (int)data[i];
  }
}

void updateArraySerial(int[] array) {
  if (array == null) {
    return;
  }

  for (int i = 0; i < min(array.length, splitString.length - 1); i++) {
    try {
      array[i] = Integer.parseInt(trim(splitString[i + 1]));
    } catch (NumberFormatException e) {
      array[i] = 0;
    }
  }
}

void updateGraphs() {
  int lastGraphPtr = globalGraphPtr - 1;

  if (lastGraphPtr < 0) {
    lastGraphPtr = numGraphPoints - 1;
  }

  for (int i = 0; i < numElectrodes; i++) {
    filteredGraph[i][globalGraphPtr] = filteredData[i];
    baselineGraph[i][globalGraphPtr] = baselineVals[i];
    touchGraph[i][globalGraphPtr]    = baselineVals[i] - touchThresholds[i];
    releaseGraph[i][globalGraphPtr]  = baselineVals[i] - releaseThresholds[i];

    if (lastStatus[i] == 0 && status[i] != 0x00) {
      // touched
      statusGraph[i][globalGraphPtr] = 1;
    } else if (lastStatus[i] != 0x00 && status[i] == 0x00) {
      // released
      statusGraph[i][globalGraphPtr] = -1;
    } else {
      statusGraph[i][globalGraphPtr] = 0;
    }
  }

  for (int i = 0; i < numElectrodes; i++) {
    lastStatus[i] = status[i];
  }

  if (++globalGraphPtr >= numGraphPoints) {
    globalGraphPtr = 0;
  }

}

void drawBars() {
  int scratchColor    = g.strokeColor;
  int scratchFill     = g.fillColor;
  float scratchWeight = g.strokeWeight;

  stroke(0, 0, 0, 0);
  strokeWeight(0);

  rectMode(CORNERS);

  for (int i = 0; i < numElectrodes; i++) {
    if (status[i] == 0) {
      fill(filteredColour);
    } else {
      fill(touchColourBar);
    }
    filteredDataLines[i].left   = graphsLeft + graphFooterLeft + 5 + ((i * (graphsWidth - graphFooterLeft)) / numElectrodes);
    filteredDataLines[i].right  = graphsLeft + graphFooterLeft + (((i + 1) * (graphsWidth - graphFooterLeft)) / numElectrodes);
    filteredDataLines[i].bottom = graphsTop + graphsHeight;
    filteredDataLines[i].top    = filteredDataLines[i].bottom - (int)(graphsHeight * ((float)filteredData[i] / (float)tenBits));

    rect(
      rescaleWidth(filteredDataLines[i].left),
      rescaleHeight(filteredDataLines[i].top),
      rescaleWidth(filteredDataLines[i].right),
      rescaleHeight(filteredDataLines[i].bottom)
    );
  }

  stroke(scratchColor);
  strokeWeight(scratchWeight);
  fill(scratchFill);
}

void drawGraphs(int[][] graph, int electrode, int graphColour) {
  int scratchColor    = g.strokeColor;
  int scratchFill     = g.fillColor;
  float scratchWeight = g.strokeWeight;

  stroke(graphColour);
  strokeWeight(2);
  fill(0, 0, 0, 0);

  int localGraphPtr = globalGraphPtr;
  int numPointsDrawn = 0;

  int thisX = -1;
  int thisY = -1;

  beginShape();

  while (numPointsDrawn < numGraphPoints) {
    thisX = (int)(graphsLeft + (numPointsDrawn * graphsWidth / numGraphPoints));
    thisY = (int)(graphsTop + (graphsHeight * (1 - ((float)graph[electrode][localGraphPtr] / (float)tenBits))));

    vertex(rescaleWidth(thisX), rescaleHeight(thisY));

    if (++localGraphPtr >= numGraphPoints) {
      localGraphPtr = 0;
    }

    numPointsDrawn++;
  }

  endShape();

  stroke(scratchColor);
  strokeWeight(scratchWeight);
  fill(scratchFill);
}

void drawDarkModeGraphs(int[][] graph, int electrode) {
  stroke(255);
  strokeWeight(5);
  fill(0, 0, 0, 0);

  int localGraphPtr = globalGraphPtr;
  int numPointsDrawn = 0;

  int thisX = -1;
  int thisY = -1;

  beginShape();

  while (numPointsDrawn < numGraphPoints) {
    thisX = (int)(graphsLeft + (numPointsDrawn * graphsWidth / numGraphPoints));
    thisY = (int)(graphsTop + (graphsHeight * (1 - ((float)graph[electrode][localGraphPtr] / (float)tenBits))));

    vertex(rescaleWidth(thisX), rescaleHeight(thisY));

    if (++localGraphPtr >= numGraphPoints) {
      localGraphPtr = 0;
    }

    numPointsDrawn++;
  }

  endShape();
}

void drawThresholds() {
  int scratchColor    = g.strokeColor;
  int scratchFill     = g.fillColor;
  float scratchWeight = g.strokeWeight;

  strokeWeight(2);

  for (int i = 0; i < numElectrodes; i++) {
    touchLines[i].left   = graphsLeft + graphFooterLeft + 6 + ((i * (graphsWidth - graphFooterLeft)) / numElectrodes);
    touchLines[i].right  = graphsLeft + graphFooterLeft - 1 + (((i + 1) * (graphsWidth - graphFooterLeft)) / numElectrodes);
    touchLines[i].top    = graphsTop + (int)(graphsHeight * (1 - (((float)baselineVals[i] - (float)fakeTouchThresholds[i]) / (float)tenBits)));
    touchLines[i].bottom = touchLines[i].top;

    stroke(touchedColour);

    line(
      rescaleWidth(touchLines[i].left),
      rescaleHeight(touchLines[i].top),
      rescaleWidth(touchLines[i].right),
      rescaleHeight(touchLines[i].bottom)
    );

    releaseLines[i].left   = graphsLeft + graphFooterLeft + 6 + ((i * (graphsWidth - graphFooterLeft)) / numElectrodes);
    releaseLines[i].right  = graphsLeft + graphFooterLeft - 1 + (((i + 1) * (graphsWidth - graphFooterLeft)) / numElectrodes);
    releaseLines[i].top    = graphsTop + (int)(graphsHeight * (1 - (((float)baselineVals[i] - (float)fakeReleaseThresholds[i]) / (float)tenBits)));
    releaseLines[i].bottom = releaseLines[i].top;

    stroke(releasedColour);

    line(
      rescaleWidth(releaseLines[i].left),
      rescaleHeight(releaseLines[i].top),
      rescaleWidth(releaseLines[i].right),
      rescaleHeight(releaseLines[i].bottom)
    );
  }

  stroke(scratchColor);
  strokeWeight(scratchWeight);
  fill(scratchFill);
}

void drawStatus(int electrode) {
  int scratchColor    = g.strokeColor;
  float scratchWeight = g.strokeWeight;

  strokeWeight(2);

  int thisX;

  int localGraphPtr = globalGraphPtr;
  int numPointsDrawn = 0;

  while (numPointsDrawn < numGraphPoints) {
    thisX = (int)(graphsLeft + (numPointsDrawn * graphsWidth / numGraphPoints));

    if (statusGraph[electrode][localGraphPtr] == 1) {
      stroke(touchColourGraph);

      line(
        rescaleWidth(thisX),
        rescaleHeight(graphsTop),
        rescaleWidth(thisX),
        rescaleHeight(graphsTop + graphsHeight)
      );
    } else if (statusGraph[electrode][localGraphPtr] == -1) {
      stroke(releaseColour);

      line(
        rescaleWidth(thisX),
        rescaleHeight(graphsTop),
        rescaleWidth(thisX),
        rescaleHeight(graphsTop + graphsHeight)
      );
    }

    if (++localGraphPtr >= numGraphPoints) {
      localGraphPtr = 0;
    }

    numPointsDrawn++;
  }

  stroke(scratchColor);
  strokeWeight(scratchWeight);
}

void drawGrid() {
  int scratchColor    = g.strokeColor;
  float scratchWeight = g.strokeWeight;

  stroke(textColour);
  strokeWeight(1);

  for (int i = 0; i <= numVerticalDivisions; i++) {
    line(
      rescaleWidth(graphsLeft),
      rescaleHeight(graphsTop + ((i * graphsHeight) / numVerticalDivisions)),
      rescaleWidth(graphsLeft + graphsWidth),
      rescaleHeight(graphsTop + ((i * graphsHeight) / numVerticalDivisions))
    );
  }

  stroke(scratchColor);
  strokeWeight(scratchWeight);
}

void drawCursor() {
  stroke(textColour);
  strokeWeight(1);

  float posY = constrain(mouseY, rescaleHeight(graphsTop), rescaleHeight(graphsTop + graphsHeight));

  line(rescaleWidth(graphsLeft), posY, rescaleWidth(graphsLeft + graphsWidth), posY);

  fill(200);
  rectMode(CORNER);
  rect(
    rescaleWidth(graphsLeft + graphsWidth) - 30,
    posY - 10,
    30,
    20
  );
}
