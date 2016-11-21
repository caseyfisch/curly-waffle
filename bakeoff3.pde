import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

int boardWidth  = 207; // 1" on LG phone LG
int boardHeight = 207; // 1" on LG phone

//int boardWidth  = 245; // 1" on LG phone MOTOROLA
//int boardHeight = 245; // 1" on LG phone

// All the phrases you could possibly want
String[] phrases;

// Variables to manage trials
int totalTrialNum = 2;
int currTrialNum  = 0;

float startTime  = 0;  // Starts when first letter is entered
float finishTime = 0;  // Records the time of when the final trial ends
float lastTime   = 0;  // Records the time the most recent trial completed

float lettersEnteredTotal  = 0;  // Num letters entered by user
float lettersExpectedTotal = 0;  // Num letters expected from user
float errorsTotal          = 0;  // Num errors running total

String currentPhrase = "";  // The current target phrase
String currentTyped  = "";  // What the user has typed so far

boolean userDone = false;
boolean userStarted = false;

float wpm          = 0;
float wpmWithError = 0;

// Variables added by me
StringBuilder inputString;  // Keeps track of full input string (this string submitted)
StringBuilder currentWord;  // Keeps track of current word for suggestions

// My keyboard
Keyboard board;

// Dictionary stuff
Map<String, Long> wordCounts;
SetTrie trie; 

// Scaling stuff
float zoom = 1;

void setup() {
  fullScreen();
  textFont(createFont("Arial", 16));
  rectMode(CENTER);
  
  // Load dictionary and phrases
  phrases = loadStrings("phrases.txt");
  Collections.shuffle(Arrays.asList(phrases));
  
  String[] words = loadStrings("enable1.txt");
  trie = new SetTrie();
  
  // Stuff words into trie for suggestion lookups later
  for (String w : words) {
    trie.load(w); 
  }
  
  wordCounts = new HashMap<String, Long>();
  String lines[] = loadStrings("counts.txt");
  
  // Load word and corresponding count
  for (String l : lines) {
    String word = l.substring(0, l.indexOf("\t")).toLowerCase();
    long count = Long.parseLong((l.substring(l.indexOf("\t") + 1)));
    wordCounts.put(word, count);
  }
  
  // Any words that appear in the dictionary, but not in count file, get count of 0
  // just to avoid null pointer exceptions later.
  for (String w : words) {
    if (wordCounts.get(w) == null) {
      wordCounts.put(w, (long) 0); 
    }
  }
  
  // Create keyboard
  board = new Keyboard(width / 2, height / 2, boardWidth, boardHeight);
  board.setUpKeys();
  
  // Initiliaze string builders
  inputString = new StringBuilder();
  currentWord = new StringBuilder();
} // SETUP

void draw() {
  background(65);
  board.display();
  
  // Finish time is non-zero, so game over
  if (finishTime != 0) {
    fill(255);
    textAlign(CENTER);
    text("Finished", 280, 150);
    text("WPM: " + wpm, 200, 170);
    text("WPM with penalty: " + wpmWithError, 200, 190);
    userDone = true;
    return;
  }
  
  // Time hasn't started yet, mouse hasn't clicked anywhere yet 
  if (startTime == 0 && !mousePressed) {
    fill(255);
    textAlign(CENTER);
    text("Click to start time!", 280, 150); //display this messsage until the user clicks!
  }
  
  // Time has started, so game on!
  if (startTime != 0) {
    rectMode(CORNER);
    textAlign(LEFT); //align the text left

    fill(128);
    text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, 70, 50); //draw the trial count
    
    fill(255);
    text("Target:   " + currentPhrase, 70, 100); //draw the target string
    text("Entered:  " + inputString.toString(), 70, 140); //draw what the user has entered thus far 
    
    // Get suggestions for input of at least 3 characters
    if (currentWord.length() > 2) {
      // Get suggestions
      List<String> suggestions = trie.findCompletions(currentWord.toString());
      // Sort by word count, descending
      Collections.sort(suggestions, FREQUENCY);
      
      // Take the first three
      List<String> smallSuggestions = new ArrayList<String>();
      for (int i = 0; i < 3; i++) {
        if (i > suggestions.size() - 1) break;
        smallSuggestions.add(suggestions.get(i));
      }
      
      // Print for now, can remove later
      for (String w : smallSuggestions) {
        println(w); 
      }
      text("Suggestions:  " + smallSuggestions.toString(), 70, 190); 
      println("================================================================================================");
    }
    
    fill(123, 123, 250);
    rect(800, 00, 200, 200); //draw next button
    fill(255);
    text("NEXT > ", 3 * width / 4, 50); //draw next label
    rectMode(CENTER);
  }
} // DRAW

int activeButtonId = -1;
boolean buttonActive = false;

void mousePressed() {
  // Time is about to start -- as long as they click outside the keyboard to start.
  if (startTime == 0 && !didMouseClick(board.x, board.y, board.w, board.h)) {
    userStarted = true;
    nextTrial();
  }
  
  if (didMouseClick(board.x, board.y, board.w, board.h)) {
    if (!userDone && userStarted) {
      for (Button b : board.keys) {
        if (didMouseClick(b.x, b.y, b.w, b.h)) {
          activeButtonId = b.id;
          buttonActive = true;
          break;
        }
      }
      
      if (!buttonActive) {
        if (didMouseClick(board.top.x, board.top.y, board.top.w, board.top.h)) {
          if (didMouseClick(board.top.sug.x, board.top.sug.y, board.top.sug.w, board.top.sug.h)) {
            // 
          } else if (didMouseClick(board.top.sdb.x, board.top.sdb.y, board.top.sdb.w, board.top.sdb.h)) {
            
          }
        }
      }
    }
  }
  
  // Did the mouse click the next button?
  if (didMouseClick(3 * width / 4, 50, 200, 200)) {
    // If yes, next trial
    nextTrial();
  }
  
} // MOUSEPRESSED

void mouseReleased() {
  if (!didMouseClick(board.x, board.y, board.w, board.h)) {
    return; 
  }
  
  if (buttonActive) {
    Button b = board.keys.get(activeButtonId);
    for (Subbutton sb : b.neighbors) {
      if (didMouseClick(sb.x, sb.y, sb.w, sb.h)) {
        inputString.append(sb.c);
        break; 
      }
    }
    buttonActive = false;
    activeButtonId = -1;
    
  }
  
  currentTyped = inputString.toString();
  
  
} // MOUSERELEASED

void mouseDragged() {
  if (!didMouseClick(board.x, board.y, board.w, board.h)) {
    return; 
  }
  
} // MOUSEDRAGGED



boolean didMouseClick(float x, float y, float w, float h) {
  // Based on rectMode(CENTER)
  return (x - w / 2 <= mouseX && mouseX <= x + w / 2 && y - h / 2 <= mouseY && mouseY <= y + h / 2);
} // DIDMOUSECLICK

void nextTrial() {
  if (currTrialNum >= totalTrialNum) { //check to see if experiment is done
    userDone = true;
    return; //if so, just return
  }

  if (startTime != 0 && finishTime == 0) { //in the middle of trials
    System.out.println("========================================================================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    System.out.println("Target phrase: " + currentPhrase); //output
    System.out.println("Phrase length: " + currentPhrase.length()); //output
    System.out.println("User typed: " + currentTyped); //output
    System.out.println("User typed length: " + currentTyped.length()); //output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + ((millis() - lastTime) / 1000) + " seconds"); //output
    System.out.println("Time taken since beginning: " + ((millis() - startTime) / 1000) + " seconds"); //output
    System.out.println("========================================================================");
    lettersExpectedTotal+=currentPhrase.length();
    lettersEnteredTotal+=currentTyped.length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  // probably shouldn't need to modify any of this output / penalty code.
  if (currTrialNum == totalTrialNum - 1) { //check to see if experiment just finished
    finishTime = millis();
    
    System.out.println("========================================================================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + ((finishTime - startTime) / 1000) + " seconds"); //output
    System.out.println("Total letters entered: " + lettersEnteredTotal); //output
    System.out.println("Total letters expected: " + lettersExpectedTotal); //output
    System.out.println("Total errors entered: " + errorsTotal); //output
    
    wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    System.out.println("Raw WPM: " + wpm); //output
    
    float freebieErrors = lettersExpectedTotal*.05; // no penalty if errors are under 5% of chars
    System.out.println("Freebie errors: " + freebieErrors); //output
    float penalty = max(errorsTotal-freebieErrors,0) * .5f;
    
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    wpmWithError = wpm - penalty;
    System.out.println("========================================================================");
    
    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime == 0) { // first trial starting now
    System.out.println("Trials beginning! Starting timer..."); //output we're done
    startTime = millis(); // start the timer!
  } else {
    currTrialNum++; // increment trial number
  }

  lastTime = millis(); //record the time of when this trial ended
  currentTyped = ""; //clear what is currently typed preparing for next trial
  
  inputString = new StringBuilder();
  currentWord = new StringBuilder();
  
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
} // NEXT TRIAL

//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
} // cOMPUTE DISTANCE

/**
 * ==================================================================================
 *   WORD COUNT COMPARATOR IMPL
 * ==================================================================================
 */

Comparator<String> FREQUENCY = new Comparator<String>() {
  public int compare(String s1, String s2) {
    Long s1_count = wordCounts.get(s1);
    Long s2_count = wordCounts.get(s2);

    return -1 * Long.compare(s1_count, s2_count);
  }
}; // FREQUENCY

/**
 * ==================================================================================
 *   KEYBOARD IMPL
 * ==================================================================================
 */
  
class Keyboard {
  float x, y, w, h;
  Topbar top;
  ArrayList<Button> keys;
  
  Keyboard(float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;
    
    top = new Topbar(x, y - h / 4, w, h / 2);
    keys = new ArrayList<Button>();
    String row1 = "qwertyuiop";
    
    float keyWidth = boardWidth / row1.length();
    float keyHeight = boardWidth / 6;
    
    int i = row1.length() * -1 / 2; // -5 to 4
    int nI = 0;
    for (char c : row1.toCharArray()) {
      Button b = new Button(nI, c, x + (i * keyWidth) + keyWidth / 2, 
                          y + keyHeight / 2, 
                          keyWidth, keyHeight);
                          
      nI++;
      keys.add(b);
      i++;
    }
    
    String row2 = "asdfghjkl"; // -4 to 4
    i = row2.length() * -1 / 2;
    for (char c : row2.toCharArray()) {
      Button b = new Button(nI, c, x + (i * keyWidth), 
                          y + keyHeight + keyHeight / 2, 
                          keyWidth, keyHeight);
      keys.add(b);
      i++;
      nI++;
    }
    
    String row3 = "zxcvbnm"; // -3 to 3
    i = row3.length() * -1 / 2;
    for (char c : row3.toCharArray()) {
      Button b = new Button(nI, c, 
                          x + (i * keyWidth), 
                          y + 2 * keyHeight + keyHeight / 2, 
                          keyWidth, keyHeight); 
      keys.add(b);
      nI++;
      i++;
    }
  }
  
  void setUpKeys() {
    for (Button b : keys) {
      b.setNeighbors(); 
    }
  }
  
  void display() {
    fill(255);
    stroke(0);
    strokeWeight(2);
    rect(x, y, w, h);
    
    top.display();
    
    for (Button b : keys) {
      b.display(); 
    }
  }
} // KEYBOARD

/**
 * ==================================================================================
 *   TOPBAR IMPL
 * ==================================================================================
 */
 
class Topbar {
  float x, y, w, h;
  Suggestions sug;
  SpaceDelbar sdb;
  
  Topbar(float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;

    sdb = new SpaceDelbar(x, y - h / 2 + h / 3, w, 2 * h / 3);
    sug = new Suggestions(x, y + h / 2 - h / 6, w, h / 3);
  }
  
  void display() {
    sug.display();
    sdb.display();
  }
} // TOPBAR

/**
 * ==================================================================================
 *   SUGGESTIONS IMPL
 * ==================================================================================
 */
 
class Suggestions {
  float x, y, w, h;
  Suggestions (float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;
  }
  
  void display() {
    fill(255);
    stroke(0);
    strokeWeight(1);
    rect(x, y, w, h);
  }
} // SUGGESTIONS

/**
 * ==================================================================================
 *   SPACEDELBAR IMPL
 * ==================================================================================
 */
 
class SpaceDelbar {
  float x, y, w, h;
  SpaceDelbar(float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;
  }
  
  void display() {
    stroke(0);
    strokeWeight(1);
    fill(255);
    rect(x, y, w, h);
  }
  
  void insertSpace() {
    
  }
  
  void deleteChar() {
    
  }
} // SPACEDELBAR 

/**
 * ==================================================================================
 *   BUTTON IMPL
 * ==================================================================================
 */
  

class Button {
  float x, y, w, h;
  int id;
  char c;
  ArrayList<Subbutton> neighbors;
  
  Button(int id, char c, float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;
    
    this.id = id;
    this.c = c;
  }
  
  void setNeighbors() {
    neighbors = new ArrayList<Subbutton>();
    
    if (id == 0 || id == 10 || id == 19) {
      neighbors.add(new Subbutton(id, board.keys.get(id).c,     board.x - board.w / 2 + board.w / 3, 
                                  board.top.y, board.w / 3, board.w / 3));
      neighbors.add(new Subbutton(id, board.keys.get(id + 1).c, board.x + board.w / 2 - board.w / 3, 
                                  board.top.y, board.w / 3, board.w / 3));
    } else if (id == 9 || id == 18 || id == 25) {
      neighbors.add(new Subbutton(id, board.keys.get(id - 1).c,     board.x - board.w / 2 + board.w / 3, 
                                  board.top.y, board.w / 3, board.w / 3));
      neighbors.add(new Subbutton(id, board.keys.get(id).c, board.x + board.w / 2 - board.w / 3, 
                                  board.top.y, board.w / 3, board.w / 3));
    } else {
      neighbors.add(new Subbutton(id, board.keys.get(id - 1).c,   board.x - board.w / 2 + board.w / 6, 
                                  board.top.y, board.w / 3, board.w / 3));
      neighbors.add(new Subbutton(id, board.keys.get(id).c,     board.x , 
                                  board.top.y, board.w / 3, board.w / 3));
      neighbors.add(new Subbutton(id, board.keys.get(id + 1).c, board.x + board.w / 2 - board.w / 6, 
                                  board.top.y, board.w / 3, board.w / 3));
    }
  }
  
  void display() {
    fill(255);
    stroke(0);
    strokeWeight(1);
    rect(x, y, w, h);
    fill(0);
    textAlign(CENTER);
    text(Character.toString(c).toUpperCase(), x, y);
    
    if (buttonActive && activeButtonId == this.id) {
       for (Subbutton sb : neighbors) {
         sb.display(); 
       }
    }
  }
} // BUTTON

/**
 * ==================================================================================
 *   BUTTON IMPL
 * ==================================================================================
 */
  

class Subbutton {
  float x, y, w, h;
  int id;
  char c;
  
  Subbutton(int id, char c, float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;
    
    this.id = id;
    this.c = c;
  }
  
  void display() {
    noStroke();
    fill(200);
    ellipse(x, y, w, h);
    fill(0);
    text(Character.toString(c).toUpperCase(), x, y);
  }
} // SUBBUTTON

/**
 * ==================================================================================
 *   TRIE IMPL
 * ==================================================================================
 */
  
public class SetTrie {

  private TreeSet<String> lines;

  public SetTrie() {
    lines = new TreeSet<String>();
  }

  public void load(String line) {
    lines.add(line);
  }

  public boolean matchPrefix(String prefix) {
    Set<String> tailSet = lines.tailSet(prefix);
    for (String tail : tailSet) {
      if (tail.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  public List<String> findCompletions(String prefix) {
    List<String> completions = new ArrayList<String>();
    Set<String> tailSet = lines.tailSet(prefix);
    for (String tail : tailSet) {
      if (tail.startsWith(prefix)) {
        completions.add(tail);
      } else {
        break;
      }
    }
    return completions;
  }
} // TRIE