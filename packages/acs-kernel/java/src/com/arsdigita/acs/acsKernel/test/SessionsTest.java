package com.arsdigita.acs.acsKernel.test;
/**
 * Test the sessions and security.  Implements all nominal QAS tests.
 *
 * @author Patrick McNeill (pmcneill@arsdigita.com)
 * @creation-date 2000-12-07
 * @cvs-id $Id$
 */

import com.meterware.httpunit.*;
import junit.framework.*;

public class SessionsTest extends TestCase
{
  private static String TEST_SERVER;
  private static WebConversation wc = null;

  public SessionsTest(String name)
  {
    super(name);
    TEST_SERVER = System.getProperty("server.url");
  }

  /**
   * Defines the collection of all tests to run.  In this case
   * we go for all the tests in this class (all the methods that
   * begin with the four characters "test").
   */
  public static Test suite()
  {
    return new TestSuite(SessionsTest.class);
  }

  // ---------- START OF TESTS ----------

    public void test_Session_Id_Cookie_is_Set_1001() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r;
        int session_ids = 0;

	// I initialize the session_values to different values so they fail
	// by default
	String session_value = "session_value";
	String new_session_value = "new_session_value";

        r=wc.getResponse(TEST_SERVER + "/doc/developer-guide/permissions.html");

        String[] cookies = wc.getCookieNames();

        for (int i = 0; i < cookies.length; i++) {
            if ( cookies[i].equals("ad_session_id") ) {
                session_ids++;
		session_value = wc.getCookieValue(cookies[i]);
            }
        }

        assertEquals("Status", 200, r.getResponseCode());
        assertEquals("Invalid number of session ids (received " + session_ids + ")", 1, session_ids);

	// we need to make sure that the session_id cookie is only set once
	// which means that it will have the same value after the second request
	// as it does after the first request
        r=wc.getResponse(TEST_SERVER + "/doc/developer-guide/permissions.html");

        cookies = wc.getCookieNames();
	session_ids = 0;

        for (int i = 0; i < cookies.length; i++) {
            if ( cookies[i].equals("ad_session_id") ) {
                session_ids++;
		new_session_value = wc.getCookieValue(cookies[i]);
            }
        }

        assertEquals("Status on second page request", 200, r.getResponseCode());
        assertEquals("Invalid number of session ids on second request (received " + session_ids + ")", 1, session_ids);
        assertEquals("Session ID set on second page request", new_session_value, session_value);
    }


    // test_ad_x_client_property tests the ad_set/get_client property interface.
    // To test this by hand
    // Go to /api-doc, go to the first package, and then set it to public only. 
    // Go back to /api-doc, select the 2nd package and set it to public only.
    // Go back to the first package and verify that it is still set to public only. 
    // Go back to the second package and verify that it is public only. 

    public void test_ad_x_client_property() throws Exception {
        WebConversation wc = ACSCommon.Login();
        WebResponse r;
	int packageLinksIndex = 0;

        r = wc.getResponse(TEST_SERVER + "/api-doc/");

	WebLink[] webLinks = r.getLinks();
	
	// by creating a string array of webLinks.length size, we 
	// initialize the variable (so it will compile) and we 
	// guarantee that the array is long enough
	String[] packageLinks = new String[webLinks.length];

        assertEquals("Status", 200, r.getResponseCode());

	for (int i = 0; i < webLinks.length; i++) {
	    if (webLinks[i].getURLString().indexOf("package-view") > -1) {
		packageLinks[packageLinksIndex] = webLinks[i].getURLString();
		packageLinksIndex++;
	    }
	}

	if (packageLinksIndex < 2) {
	    assertEquals("Not enough packages on /api-doc/", packageLinksIndex, 2);
	} else {
	    for (int i = 0; i < 2; i++) {
		// now that we have the correct number of links, we need to loop 
		// through them and perform the test
		r = wc.getResponse(TEST_SERVER + "/api-doc/" + packageLinks[i] + "&public_p=1");

		assertEquals("Page Not Found /api-doc/" + packageLinks[i] + "&public_p=1", 200, r.getResponseCode());
		assert(r.toString() + "Failed to change package to Public Only: url=/api-doc/" + packageLinks[i], r.toString().indexOf("<strong>Public Only</strong>") != -1);

	    }
	    
	    // we have now set the first two items to be Public Only.  
	    // so, we need to go back and make sure that they are still public
	    // only and then we want to change them back to ALL

	    for (int i = 0; i < 2; i++) {
		// now that we have the correct number of links, we need to loop 
		// through them and perform the test
		r = wc.getResponse(TEST_SERVER + "/api-doc/" + packageLinks[i]);

		assertEquals("Page Not Found /api-doc/" + packageLinks[i], 200, r.getResponseCode());
		assert("Package did not remain public: url=/api-doc/" + packageLinks[i], r.toString().indexOf("<strong>Public Only</strong>") != -1);

		// now, lets change it back to be ALL
		r = wc.getResponse(TEST_SERVER + "/api-doc/" + packageLinks[i] + "&public_p=0");
	    }
	}
    }
}
