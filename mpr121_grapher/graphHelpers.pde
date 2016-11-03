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

void setupGraphs() {
  filteredData      = new int[numElectrodes];
  baselineVals      = new int[numElectrodes];
  diffs             = new int[numElectrodes];
  touchThresholds   = new int[numElectrodes];
  releaseThresholds = new int[numElectrodes];
  status            = new int[numElectrodes];
  lastStatus        = new int[numElectrodes];

  for (int i = 0; i < numElectrodes; i++) {
    status[i] = 128; // 128 is an unused value from the Arduino input
    lastStatus[i] = 128;
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

  for(int i = 0; i < min(array.length, splitString.length - 1); i++){
    try {
      array[i] = Integer.parseInt(trim(splitString[i + 1]));
    } catch (NumberFormatException e) {
      array[i] = 0;
    }
  }
}

void updateGraphs() {
  int lastGraphPtr = globalGraphPtr-1;
  if (lastGraphPtr < 0) { lastGraphPtr = numGraphPoints - 1; }

  for (int i = 0; i < numElectrodes; i++) {
    filteredGraph[i][globalGraphPtr] = filteredData[i];
    baselineGraph[i][globalGraphPtr] = baselineVals[i];
    touchGraph[i][globalGraphPtr]    = baselineVals[i] - touchThresholds[i];
    releaseGraph[i][globalGraphPtr]  = baselineVals[i] - releaseThresholds[i];

    if (lastStatus[i] == 0 && status[i] != 0x00) {
      // touched
      statusGraph[i][globalGraphPtr] = 1;
    }
    else if(lastStatus[i] != 0x00 && status[i] == 0x00) {
      // released
      statusGraph[i][globalGraphPtr] = -1;
    }
    else {
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

void drawGraphs(int[][] graph, int electrode, int graphColour) {
  int scratchColor    = g.strokeColor;
  int scratchFill     = g.fillColor;
  float scratchWeight = g.strokeWeight;

  stroke(graphColour);
  strokeWeight(2);
  fill(0,0,0,0);

  int localGraphPtr = globalGraphPtr;
  int numPointsDrawn = 0;

  int thisX = -1;
  int thisY = -1;

  beginShape();

  while (numPointsDrawn < numGraphPoints) {
    thisX = (int)(graphsLeft + (numPointsDrawn * graphsWidth / numGraphPoints));
    thisY = (int)graphsTop + (int)(graphsHeight * (1 - ((float)graph[electrode][localGraphPtr] / (float)tenBits)));

    vertex(thisX, thisY);

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

void drawLevels(int[] arrayToDraw) {
  for (int i=0; i < arrayToDraw.length; i++) {
    rect(40 + 75 * i, 295 - arrayToDraw[i], 50, 10);
  }
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
      stroke(touchColour);
      line(thisX, graphsTop, thisX, graphsTop+graphsHeight);
    }
    else if (statusGraph[electrode][localGraphPtr] == -1) {
      stroke(releaseColour);
      line(thisX, graphsTop, thisX, graphsTop+graphsHeight);
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

  for (int i=0; i <= numVerticalDivisions; i++) {
    line(
        graphsLeft,
        graphsTop + i * (graphsHeight / numVerticalDivisions),
        graphsLeft + graphsWidth,
        graphsTop + i * (graphsHeight / numVerticalDivisions)
    );
  }

  stroke(scratchColor);
  strokeWeight(scratchWeight);
}

void drawText(int[] arrayToDraw) {
  fill(0);
  for (int i=0; i < arrayToDraw.length; i++) {
    text(arrayToDraw[i], 20, 50 + 20 * i);
  }
}