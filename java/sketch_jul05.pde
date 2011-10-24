import traer.physics.*;
import org.json.*;
import java.net.*;
import java.util.*;
import java.lang.*;

import java.io.File;
import java.io.FileInputStream;

final float NODE_SIZE = 10;
final float EDGE_LENGTH = 150;
final float EDGE_STRENGTH_MULT = 0.03;
final float SPACER_STRENGTH = 700;

final int LOADINTERVAL = 10;

final String JSONURL = "http://www.raymondbrooks.co.uk:8001/dump.json";

ParticleSystem physics;
float scale = 1;
int translateX = 0;
int translateY = 0;

boolean timerFlag = false;

HashMap people = new HashMap();
//HashMap connections = new HashMap();
String[] myArray = new String[100];

// PROCESSING /////////////////////////////////////

FileInputStream fis = null;

/******************************************************************************************
* Person class - viz - a node
******************************************************************************************/

public class Person extends Particle {
	private String name;
	private ArrayList springs;
	private ArrayList forces;
	
	public Person(String n) {
		
		super();
		
		name = n;
  		
		set( random( -400, 400 ), random( -400, 400 ), 0 );
		
		springs = new ArrayList();
		forces = new ArrayList();
	}
		
	public String getName() {
		return name;
	}
	
	//replace getParticle with the classed object! EASY!
	public Particle getParticle() {
		return this;
	}
	
	//no need for this longer
	public void removeParticle() {
		physics.removeParticle(particle);
		particle = null;
	}
		
	public Spring getSpring(int i) {
		return (Spring)springs.get(i);
	}
	
	public int numSprings() {
		return springs.size();
	}
	
	//all springs, including foreign connections
	public int totalSprings() {
		return springs.size() + getOtherEnds().size();
	}
	
	public void addSpring(Person otherEnd, int strength) {
		println("making connection between " + getName() + " and " + otherEnd.getName());
		float edgeStrength = log(1 + strength) * EDGE_STRENGTH_MULT;
		Spring spring = physics.makeSpring(this, otherEnd, edgeStrength, 0, EDGE_LENGTH);
		println("adding spring strength " + strength);
		springs.add(spring);
	}
		
	synchronized public ArrayList getOtherEnds() {
		ArrayList otherEnds = new ArrayList();
		
		HashMap ppl = new HashMap(people);
		Iterator users = ppl.keySet().iterator();
	  
		while (users.hasNext()) {
			Person p = (Person)ppl.get(users.next().toString());
			for (int i = 0; i < p.numSprings(); i++) {
				if (p.getSpring(i).getTheOtherEnd() == particle) {
					otherEnds.add(p.getName());
				}
			}
		}
				
		return otherEnds;
	}
	
	public void addForce(Particle otherEnd) {
		forces.add(physics.makeAttraction( particle, otherEnd, -SPACER_STRENGTH, 20 ));
	}
	
	void setMass() {
		particle.setMass(1);
	}
	
	public void addReactions(JSONObject connections, JSONObject listdata) {

		springs = new ArrayList();
		forces = new ArrayList();
		
		Iterator users = connections.keys();
		while (users.hasNext()) {
			
			int strength = 1;
			
			Person p = (Person) people.get(users.next().toString());
						
			try {
				strength = connections.getInt(p.getName());
				try {
					JSONObject conn = listdata.getJSONObject(p.getName());
					strength += conn.getInt(name);
				} catch (JSONException e) {
					//There should probably be some better exception handling here...
					println ("inside +" + e.toString());
				}
				
			} catch (JSONException e) {
				//There should probably be some better exception handling here...
				println ("inside +" + e.toString());
			}
			if (name.equals(p.getName()) == false && getOtherEnds().indexOf(name) < 0) {
				addSpring(p, strength);
			}
		}
		
		users = people.keySet().iterator();
	  
		while (users.hasNext()) {
			Person p = (Person)people.get(users.next().toString());
			addForce(p);

		}

		return;
	}
	
	public void removeReactions() {
		for (int i = 0; i  < springs.size(); i++) {
			physics.removeSpring((Spring)springs.get(i));
			springs.remove(i);
		}
				
		for (int i = 0; i  < forces.size(); i++) {
			physics.removeAttraction((Attraction)forces.get(i));
			forces.remove(i);
		}
	}
	
}


/******************************************************************************************
* Read the JSON data from the web server
******************************************************************************************/

JSONObject pullJSON(String targetURL) {
	String jsonTxt = "";   //String to hold the json txt
	JSONObject retVal = new JSONObject();  //return val
	InputStream  in = null;                //Data from the URL
	
	//Connect to the URL and pull  the json data into a string
	try {
		URL url = new URL(targetURL);          //Create the URL
		in = url.openStream();                 //Get a stream to it
		byte[] buffer = new byte[8192];
		int bytesRead;
		while ( (bytesRead = in.read(buffer)) != -1) {
			String outStr = new String(buffer, 0, bytesRead);
			jsonTxt += outStr;
		}
		in.close();
	} catch (Exception e) {
		//There should probably be some better exception handling here...
		System.out.println (e);
	}
	
	//Now convert to a JSON object
	try {
		retVal = new JSONObject(jsonTxt);
	} catch (JSONException e) {
		//There should probably be some better exception handling here...
		println (e.toString());
	}
	
	return retVal;  // Return the json object
}

/******************************************************************************************
* Read the JSON data from a file
******************************************************************************************/

JSONObject pullJSONFromFile(String fileName) {
	String jsonTxt = "";   //String to hold the json txt
	JSONObject retVal = new JSONObject();  //return val
	
	println("got filename " + fileName);
	
	File file = new File(fileName);
	FileInputStream fis = null;
	BufferedInputStream bis = null;
	DataInputStream dis = null;
	
	try {
		fis = new FileInputStream(file);
		
		// Here BufferedInputStream is added for fast reading.
		bis = new BufferedInputStream(fis);
		dis = new DataInputStream(bis);
	
		// dis.available() returns 0 if the file does not have more lines.
		while (dis.available() != 0) {
		  // this statement reads the line from the file and print it to
		  // the console.
		  jsonTxt += dis.readLine();
		}
	  
		println(jsonTxt);
	
		// dispose all the resources after using them.
		fis.close();
		bis.close();
		dis.close();
	} catch (FileNotFoundException e) {
		e.printStackTrace();
	} catch (IOException e) {
		e.printStackTrace();
	}
    
	//Now convert to a JSON object
	try {
		retVal = new JSONObject(jsonTxt);
	} catch (JSONException e) {
		println (e.toString());
		//There should probably be some better exception handling here...
	}
	return retVal;  // Return the json object
}

/******************************************************************************************
* Timer class - to read the data from the sever
* Nicked and modified from http://www.exampledepot.com/egs/java.util/ScheduleRepeat.html
******************************************************************************************/

public class loadJSONTimer extends TimerTask {  
	private int timerInterval;
	
	public loadJSONTimer(int timeInterval) {
		this.timerInterval=timeInterval * 1000;
	}

	public void run() {
		reloadJSON();
	}
}

/******************************************************************************************
* Processing directives
******************************************************************************************/

void setup() {
	size( 1000, 1000 );
	smooth();
	strokeWeight( 1 );
	ellipseMode( CENTER );       
	
	physics = new ParticleSystem( 0, 0.1 );
	//physics.setIntegrator( ParticleSystem.MODIFIED_EULER ); 
	physics.setDrag( 0.5 );
	//physics.setGravity( 1.0 );
	textFont( loadFont( "URWGothicL-Demi-10.vlw" ) );

	physics.clear();
	
	Particle centre = physics.makeParticle(10, 0, 0, 0);
	centre.makeFixed();
	
	java.util.Timer t1 = new java.util.Timer();
	loadJSONTimer tt = new loadJSONTimer(0);
	t1.schedule(tt, 0, LOADINTERVAL * 1000);
	
	background( 0 );
	fill( 128 );
	updateCentroid();
		
}

void draw()
{

		background( 0 );
		fill( 128 );
		text( "" + (physics.numberOfParticles() - 1) + " USERS\n" + (int)frameRate + " FPS", 10, 20 );
		text( "+/left mouse - zoom in\n-/right mouse - zoom out\na / middle mouse - autocentre/centre", 10, 50 );

		translate(translateX, translateY);
		scale( scale );
		
		drawNetwork();
		if ( physics.numberOfParticles() > 1 ) {
			
			HashMap ppl = new HashMap(people);
			Iterator users;
			users = ppl.keySet().iterator();
			fill(255);
			
			while (users.hasNext()) {
				Person u = (Person)ppl.get(users.next().toString());
				if (u.totalSprings() > 0) {
					text(u.getName(), u.position().x() + 10, u.position().y() + 4);
				}
			}
		}


		doTick();		
}

synchronized void doTick() {
	physics.tick();
}

synchronized void drawNetwork() {      
	
		HashMap ppl = new HashMap(people);
		Iterator users;

		if (true) {
			stroke( 64 );
			
			beginShape( LINES );
			
			users = ppl.keySet().iterator();
			
			while (users.hasNext()) {
				Person u = (Person)ppl.get(users.next().toString());
				for (int i = 0; i < u.numSprings(); i++) { 
					Spring e = u.getSpring( i );
					strokeWeight( e.strength() / EDGE_STRENGTH_MULT);
					Particle a = e.getOneEnd();
					Particle b = e.getTheOtherEnd();
					vertex( a.position().x(), a.position().y() );
					vertex( b.position().x(), b.position().y() );
				}
			}
			
			endShape();
			
			strokeWeight( 1 );
		}
		
		// draw vertices
		if (true) {
			noStroke();
			
			users = ppl.keySet().iterator();
			fill( 192, 192, 0 );
		  
			while (users.hasNext()) {
				Person u = (Person)ppl.get(users.next().toString());
				if (u.totalSprings() > 0) {
					ellipse( u.position().x(), u.position().y(), NODE_SIZE * sqrt(u.totalSprings() + 1), NODE_SIZE * sqrt(u.totalSprings() + 1));
				}
			}
		}
	  
		/*if (false) {
			users = ppl.keySet().iterator();
			fill(255);
			
			while (users.hasNext()) {
				Person u = (Person)ppl.get(users.next().toString());
				if (u.totalSprings() > 0) {
					Particle p = u.getParticle();
					text(u.getName(), p.position().x() + 10, p.position().y() + 4);
				}
			}
		}*/
		
}

void keyPressed()
{
  	if (key == '+') {
  		scale += 0.2;
  	} else if (key == '-') {
  		scale -= 0.2;
  	} else if (key == 'a') {
  		updateCentroid();
  		translate( width/2 , height/2 );
  		scale(scale);
		translate( translateX, translateY );
  	}
}

void mousePressed() {
	println (mouseButton);
	if (mouseButton == 37) {
		translateX -= (int)(mouseX - width / 2);
		translateY -= (int)(mouseY - height / 2);
		scale += 0.2;
	} else if (mouseButton == 39) {
		translateX -= (int)(mouseX - width / 2);
		translateY -= (int)(mouseY - height / 2);
		scale -= 0.2;
	} else if (mouseButton == 3) {
		translateX -= (int)(mouseX - width / 2);
		translateY -= (int)(mouseY - height / 2);
	}
}

void mouseButton() {
}

void mouseDragged() {
		
	
}

synchronized void updateCentroid()
{
	float 
		xMax = Float.NEGATIVE_INFINITY, 
		xMin = Float.POSITIVE_INFINITY, 
		yMin = Float.POSITIVE_INFINITY, 
		yMax = Float.NEGATIVE_INFINITY;

	Iterator users = people.keySet().iterator();
	  
	while (users.hasNext()) {
		Person u = (Person)people.get(users.next().toString());
		if (u.numSprings() > 0 || u.getOtherEnds().size() > 0) {
			xMax = max( xMax, u.position().x() ) + 5;
			xMin = min( xMin, u.position().x() );
			yMin = min( yMin, u.position().y() );
			yMax = max( yMax, u.position().y() );
		}
	}
	
	
	float deltaX = xMax-xMin;
	float deltaY = yMax-yMin;
	
	translateX = (int)(xMin + 0.5*deltaX + width / 2);
	translateY = (int)(yMin +0.5*deltaY + height / 2);
  
	if ( deltaY > deltaX ) {
		scale = height/(deltaY+50);
	} else {
		scale = width/(deltaX+50);
	}
}

HashMap getNetworks() {
	//find individual networks
	//and return a hashmap of string arrays
	HashMap networks = new HashMap();
	
	return networks;
	
}

synchronized void reloadJSON() { // add the task here
		JSONObject listdata = pullJSON(JSONURL);
		//JSONObject listdata = pullJSONFromFile("/www/node/js-bin/twitter/data/dump.json");
		
		//println("Loading data from: " + System.getProperty("user.home") + "/dump.json");
		//JSONObject listdata = pullJSONFromFile(System.getProperty("user.home") + "/dump.json");
	  
		//now we must:

		//set fl;ag to avoid concurrency exception
		
		timerFlag = true;
		
		//1. add any new nodes

		Iterator users = listdata.keys();
		
	
		while (users.hasNext()) {
			String user = users.next().toString();
				if (!people.containsKey(user)) {
					println("adding " + user);
					people.put(user, new Person(user));
				}
		}
		
		//2. remove connections
		
		users = listdata.keys();
		
		while (users.hasNext()) {
			String user = users.next().toString();
			Person p = (Person)people.get(user);
			p.removeReactions();
		}
	
		//3. make springs and add repulsive force

		users = people.keySet().iterator();

		println("making springs, adding repulsion");
		
		while (users.hasNext()) {
			String user = users.next().toString();
			Person p = (Person)people.get(user);
			try {
				//we replace the string array with a hashmap of hashmaps!
				//this will totally affect 
				JSONObject connections = listdata.getJSONObject(p.getName());
				
				p.addReactions(connections, listdata);
			} catch (JSONException e) {
				println(e.toString());
			}
		}
	
		//4. add mass and remove unused users
		
		ArrayList toRemove = new ArrayList();
		users = people.keySet().iterator();
		
		while (users.hasNext()) {
			String user = users.next().toString();
			Person p = (Person)people.get(user);
			if (p.totalSprings() <= 0) {
				println("removing unused user " + p.getName());
				p.removeReactions();
				p.removeParticle();
				//people.remove(user);
				toRemove.add(user);
			} else {
				p.setMass();
			}
		}
		
		//avoid concurrency!
		for (int i = 0; i < toRemove.size(); i++) {
			String user = (String)toRemove.get(i);
			people.remove(user);
		}
				
		timerFlag = false;
}
