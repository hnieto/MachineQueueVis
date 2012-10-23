// JAXB is part of Java 6.0, but needs to be imported manually
import javax.xml.bind.*;

// zoom, pan, spin
import peasy.*;

// our class for parsing xml file
// this class is defined in its own tab in the Processing PDE
XMLparse file;
List<JobToShapes> js = new ArrayList<JobToShapes>();
Helix h1;
PeasyCam cam;

void setup() {
  size(1000, 700, P3D); 
  cam = new PeasyCam(this, 0, 0, 0, 7000);

  parseFile();
  createShapesFromFile();
  h1 = new Helix(js);
//  printList();
}

void draw() {
  background(0);
  lights();
  h1.display();
} 

void parseFile() {
  // the following 2 lines of code will load the xml file and map its contents
  // to the nested object hierarchy defined in the XMLparse class (see below)
  try {
    // setup object mapper using the XMLparse class
    JAXBContext context = JAXBContext.newInstance(XMLparse.class);
    // parse the XML and return an instance of the XMLparse class
    file = (XMLparse) context.createUnmarshaller().unmarshal(createInput("rangerQSTAT-long.xml"));
  } 
  catch(JAXBException e) {
    // if things went wrong...
    println("error parsing xml: ");
    e.printStackTrace();
    // force quit
    System.exit(1);
  }
}

void createShapesFromFile() {
  int RANGER_SLOTS_PER_NODE = 16;
  int LONGHORN_SLOTS_PER_NODE = 16;
  int STAMPEDE_SLOTS_PER_NODE = 16;

  // find the largest slot count in the current qstat xml file
  JobComparator comparator = new JobComparator();
  int currMaxSlots = Collections.max(file.jobs, comparator).slots;

  for (Job j : file.jobs) {  // for each Job Object j in file.jobs
    if(j.state.equals("r")){  // only use running states. ignore pending (qw) and transitional (dr) states
      color jobColor = color(random(255), random(255), random(255)); 
      String[] parseQueueName = split(j.queue_name, '@'); 
  
      for (int i=0; i<(j.slots/RANGER_SLOTS_PER_NODE); i++) {
        js.add(new JobToShapes(calculateRadius(j.slots, currMaxSlots), parseQueueName[0], j.JAT_start_time, jobColor));
      }
    }
  }
}

void printList() {
  for (Job jbs : file.jobs) {  // for each Job Object jbs in file.jobs
  
    // print start time
    String[] parseTime = split(jbs.JAT_start_time, 'T');
    println(parseTime[0] + " " + parseTime[1]); 
    
    // print job state
    println(jbs.state);
  }
}

float calculateRadius(int jobSlots, int _maxSlots) {
  float minSlots = 1;   // x0
  float minRadius = 5;  // y0

  float maxSlots = _maxSlots; // x1
  float maxRadius = 15;   // y1

  // interpolate sphere radius
  return minRadius + (((jobSlots-minSlots)*maxRadius-(jobSlots-minSlots)*minRadius)/(maxSlots-minSlots));
}
