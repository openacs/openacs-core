package com.arsdigita.acs.acsKernel.test;
/**
 * Provide functions to perform commonly needed tasks, such as logging in 
 * and creating a new user. 
 *
 * @author Patrick McNeill (pmcneill@arsdigita.com)
 * @creation-date 2000-12-07
 * @cvs-id $Id$
 */

import com.meterware.httpunit.*;

public class ACSCommon
{
    private static String TEST_SERVER = System.getProperty("server.url");
    private static String username = System.getProperty("server.username");
    private static String password = System.getProperty("server.password");
    private static String adminUsername = System.getProperty("server.adminUsername");
    private static String adminPassword = System.getProperty("server.adminPassword");

    private static WebConversation wc = null;
    private static WebConversation adminWC = null;

    /*
     * This function will use the system username and password as an ACS
     * login.  If the user does not exist, it will be created.  A session
     * containing all needed ACS cookies will be returned.
     *
     * This function requires strict formatting of the hidden variables on 
     * the registration pages.  It is based off of a 4.0.2 checkout.  The 
     * variables must be of the exact form:
     *      <input type=hidden name="variable_name" value="value">
     * Any deviation will cause failure.
     */
    public static WebConversation Login () throws Exception {
        WebResponse r = null;

        if ( wc != null ) return wc;

        wc = new WebConversation();

        r = wc.getResponse(TEST_SERVER+"/register/index");

        WebForm form = r.getForms()[0];

        WebRequest req = form.getRequest();
        req.setParameter("email",username);
        req.setParameter("password",password);
        r = wc.getResponse(req);

        if (r.getURL().toString().equals(TEST_SERVER+"/pvt/home")) {
            System.out.println("User logged-in");
        } else {
            form = r.getForms()[0];
            req = form.getRequest();

            req.setParameter("password_confirmation",password);
            req.setParameter("first_names","Test");
            req.setParameter("last_name","User");
            req.setParameter("question","password");
            req.setParameter("answer",password);

            r = wc.getResponse(req);

            if (!r.getURL().toString().equals(TEST_SERVER+"/pvt/home")) {
                return null;
            }

            System.out.println("User created");
        }

        return wc;

    }

    /*
     * This function will use the system administration username and password 
     * as an ACS login.  If the user does not exist, it throws an exception
     * since it is not able to log in as an administrator
     *
     */
    public static WebConversation AdminLogin () throws Exception {
        WebResponse r = null;

        if ( adminWC != null ) return adminWC;

        adminWC = new WebConversation();

        r = adminWC.getResponse(TEST_SERVER+"/register/index");

        WebForm form = r.getForms()[0];

        WebRequest req = form.getRequest();
        req.setParameter("email",adminUsername);
        req.setParameter("password",adminPassword);
        r = adminWC.getResponse(req);

        if (r.getURL().toString().equals(TEST_SERVER+"/pvt/home")) {
            System.out.println("Admin User logged-in");
        } else {
	    // we were not able to log in as an administrator
	    // so we throw an exception
	    throw new Exception("Cannot log in as Administrator in ACSCommon.java");
        }

        return adminWC;
    }
}
