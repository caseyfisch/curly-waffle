import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

//int boardWidth  = 207; // 1" on LG phone LG
//int boardHeight = 207; // 1" on LG phone
int boardWidth  = 245; // 1" on LG phone MOTOROLA
int boardHeight = 245; // 1" on LG phone

// All the phrases you could possibly want
String[] phrases;

// Variables to manage trials
int totalTrialNum = 4;
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

void setup() {
  fullScreen();
  textFont(createFont("Arial", 14));
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
    println("WPM with error: " + wpmWithError);
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

void mousePressed() {
  
} // MOUSEPRESSED

void mouseReleased() {
  
} // MOUSERELEASED

void mouseDragged() {
  
} // MOUSEDRAGGED



boolean didMouseClick(float x, float y, float w, float h) {
  // Based on rectMode(CENTER)
  return (x - w / 2 <= mouseX && mouseX <= x + w / 2 && y - h / 2 <= mouseY && mouseY <= y + h / 2);
} // DIDMOUSECLICK

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
  
  Keyboard(float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;
  }
  
  void display() {
    fill(255);
    stroke(0);
    strokeWeight(2);
    rect(x, y, w, h);
  }
} // KEYBOARD

/**
 * ==================================================================================
 *   BUTTON IMPL
 * ==================================================================================
 */
  

class Button {
  float x, y, w, h;
  
  Button(float inX, float inY, float inW, float inH) {
    x = inX;
    y = inY;
    w = inW;
    h = inH;
  }
  
  void display() {
    
  }
} // BUTTON

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