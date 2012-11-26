import peasy.*;

HUD hud1,hud2,hud3,hud4;
PeasyCam cam;
PMatrix3D baseMat; // used for peasycam + HUD + lights fix
int drawHud = 2;

int[][] colorArray = new int[0][2]; 
PImage colorImage; 

String PATH = "/Users/eddie/Programming/Processing/MachineQueueVis/data/"; // SPECIFY ABSOLUTE PATH WHEN USING MPE
String XMLFILE = "rangerQSTAT-short.xml"; 
Job[] jobs; // array of Job Objects created from XML

Helix h1;
float deltaZ = 2;
float helixRadius = 200;
float rotz = 0;

private String[] usage = { "USAGE",
                           "d = visualization description",
                           "l = largest job information",
                           "s = smallest job information",
                           "up/down = increase/decrease helix length",
                           "right/left = increase helix radius" };
                           
private String[] description = { "MACHINE QUEUE VISUALIZATION",
                                  "1. Each job is represented by a cluster of same-colored spheres", 
                                  "2. Each sphere is a node",
                                  "3. Sphere size is proportional to the number of nodes per job",
                                  "4. Each cylinder represents allocated time", 
                                  "5. Color along cylinder represents time used" };
         
private String[] smallestJob = new String[8];
private String[] largestJob = new String[8];

/* UNCOMMENT FOR USE ON MINI-LASSO */
/*boolean sketchFullScreen() {
  return true;
} */

void setup() {
  //size(displayWidth,displayHeight,OPENGL); // UNCOMMENT FOR USE ON MINI-LASSO
  size(1300,500,OPENGL);
  baseMat = g.getMatrix(baseMat);
  frameRate(60);
  
  cam = new PeasyCam(this, 0, 0, 0, 2000);
  colorImage = loadImage(PATH + "colors.png"); // SPECIFY ABSOLUTE PATH WHEN USING MPE
  createColorArr();
  parseFile();
  h1 = new Helix(jobs,getMaxSlotsPosition(),colorArray); 
  h1.createHelix();
  initHUDs();
}

void draw() {
  background(0);
  smooth(8);

  // save peasycam matrix and reset original
  pushMatrix();
  g.setMatrix(baseMat);
  ambientLight(40, 40, 40);
  directionalLight(255, 255, 255, -150, 40, -140);
  popMatrix();

/*  h1.setDeltaZ(deltaZ);
  h1.setRadius(helixRadius); */
  
  rotateZ(rotz);
  h1.displayHelix();

  hud1.draw();
  switch(drawHud) {
    case 3: 
      hud3.draw();
      break;
    case 4: 
      hud4.draw();
      break;
    default:
      hud2.draw();
      break;
  }
  rotz += .0009;
  //println(frameRate);
} 

void initHUDs(){
  int largestJobPosition = getMaxSlotsPosition();
  int smallestJobPosition = getMinSlotsPosition();
  
  largestJob[0] = "LARGEST JOB";
  largestJob[1] = "Job Number: " + jobs[largestJobPosition].getJobNum();
  largestJob[2] = "Job Priority: " + jobs[largestJobPosition].getJobPrio();
  largestJob[3] = "Job Name: " + jobs[largestJobPosition].getJobName();
  largestJob[4] = "Job Owner: " + jobs[largestJobPosition].getJobOwner();
  largestJob[5] = "Job Start Time: " + jobs[largestJobPosition].getStartTime();
  largestJob[6] = "Queue Name: " + jobs[largestJobPosition].getQueueName(); 
  largestJob[7] = "Slot Count: " + jobs[largestJobPosition].getSlots();
  
  smallestJob[0] = "SMALLEST JOB";
  smallestJob[1] =  "Job Number: " + jobs[smallestJobPosition].getJobNum();
  smallestJob[2] = "Job Priority: " + jobs[smallestJobPosition].getJobPrio();
  smallestJob[3] = "Job Name: " + jobs[smallestJobPosition].getJobName();
  smallestJob[4] = "Job Owner: " + jobs[smallestJobPosition].getJobOwner();
  smallestJob[5] = "Job Start Time: " + jobs[smallestJobPosition].getStartTime();
  smallestJob[6] = "Queue Name: " + jobs[smallestJobPosition].getQueueName();
  smallestJob[7] = "Slot Count: " + jobs[smallestJobPosition].getSlots(); 
  
  hud1 = new HUD(this,usage,"topLeft");
  hud2 = new HUD(this,description,"topRight");
  hud3 = new HUD(this,largestJob, "topRight");
  hud4 = new HUD(this,smallestJob, "topRight"); 
}

void createColorArr() {
  //loop through all the pixels of the image
  for (int i = 0; i < colorImage.pixels.length; i++) {
    boolean colorExists = false; //bollean variable that checks if the color already exists in the array

    //loop through the values in the array
    for (int j = 0; j < colorArray.length; j++) {
      if (colorArray[j][0] == colorImage.pixels[i]) {
        int count = colorArray[j][1];
        colorArray[j][1] = count +1;
        colorExists = true; //color already exists in the array
      }
    }

    //if the color hasn't been added to the array
    if (colorExists == false) {
      colorArray = (int[][])append(colorArray, new int[] {
        colorImage.pixels[i], 1
      }); //add it
    }
  }
}

void parseFile() {
  // Load an XML document
  XML xml = loadXML(PATH + XMLFILE);

  // Get all the job_list elements
  XML[] jobList = xml.getChild("queue_info").getChildren("job_list");
  jobs = new Job[jobList.length];

  for (int i=0; i < jobList.length; i++ ) {
    XML jobNumElem = jobList[i].getChild("JB_job_number"); 
    XML jobPrioElem = jobList[i].getChild("JAT_prio"); 
    XML jobNameElem = jobList[i].getChild("JB_name"); 
    XML jobOwnerElem = jobList[i].getChild("JB_owner");
    XML jobStateElem = jobList[i].getChild("state");
    XML jobStartTimeElem = jobList[i].getChild("JAT_start_time");
    XML jobQueueNameElem = jobList[i].getChild("queue_name");
    XML jobSlotsElem = jobList[i].getChild("slots"); 

    int num = int(jobNumElem.getContent());
    float prio = float(jobPrioElem.getContent());
    String name = jobNameElem.getContent();
    String owner = jobOwnerElem.getContent();
    String currState = jobStateElem.getContent();  
    String startTime = jobStartTimeElem.getContent();
    String queue = jobQueueNameElem.getContent(); 
    int slotNum = int(jobSlotsElem.getContent()); 

    jobs[i] = new Job(num, prio, name, owner, currState, startTime, queue, slotNum);
  }
}

int getMaxSlotsPosition() {
  if (jobs.length == 0) return -1;
  else {
    int maxSlots = jobs[0].getSlots();
    int maxPos = 0;
    for (int i=1; i<jobs.length; i++) {
      if (jobs[i].getSlots() > maxSlots){
        maxSlots = jobs[i].getSlots();
        maxPos = i;
      }
    }
    return maxPos;
  }
}

int getMinSlotsPosition() {
  if (jobs.length == 0) return -1;
  else {
    int minSlots = jobs[0].getSlots();
    int minPos = 0;
    for (int i=1; i<jobs.length; i++) {
      if (jobs[i].getSlots() < minSlots){
        minSlots = jobs[i].getSlots();
        minPos = i;
      }
    }
    return minPos;
  }
}

void keyPressed() {
  if(key == CODED){
    if(keyCode == UP){
      if((deltaZ += 0.1) > 10) deltaZ = 10;
    }else if(keyCode == DOWN){
      if((deltaZ -= 0.1) < 2) deltaZ = 2;
    }else if(keyCode == RIGHT){
      if((helixRadius += 10) > 400) helixRadius = 400;
    }else if(keyCode == LEFT){
      if((helixRadius -= 10) < 200) helixRadius = 200;
    }
  }else{
    if (key == 'd') drawHud = 2;
    else if (key == 'l') drawHud = 3;
    else if (key == 's') drawHud = 4;
  }
}
