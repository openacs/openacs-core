package com.arsdigita.acs.acsTemplating.test;
/**
 * Test the templating system.  Implements all QAS tests except 361 and 561
 * (since they're stress tests) and 405 (since I don't have a good idea of how
 * to test it yet).
 *
 * @author Patrick McNeill (pmcneill@arsdigita.com)
 * @creation-date 2000-12-07
 * @cvs-id $Id$
 */

import com.meterware.httpunit.*;
import junit.framework.*;
import com.arsdigita.acs.acsKernel.test.ACSCommon;

public class TemplatingTest extends TestCase
{
  private static String TEST_SERVER;

  public TemplatingTest(String name)
  {
    super(name);
    TEST_SERVER = System.getProperty("server.url") + "/doc/acs-templating/demo/";
  }

  /**
   * Defines the collection of all tests to run.  In this case
   * we go for all the tests in this class (all the methods that
   * begin with the four characters "test").
   */
  public static Test suite()
  {
    return new TestSuite(TemplatingTest.class);
  }

  // ---------- START OF TESTS ----------


    public void test_Hello_World_385() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r;

        r = wc.getResponse(TEST_SERVER+"hello");

        assertEquals("Status", 200, r.getResponseCode() );
        assert("Incorrect Output", r.toString().indexOf("Hello World") != -1);
    }

    public void test_Simple_Include_390() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r;

        r = wc.getResponse(TEST_SERVER + "include");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Relative path failed", r.toString().indexOf("Hello <b>Barney</b>") != -1);
        assert("Absolute path failed", r.toString().indexOf("Hello <b>Anders</b>") != -1);
    }

    public void test_Master_Template_391() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;

        r = wc.getResponse(TEST_SERVER + "slave");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Master not present", r.toString().indexOf("<title>My") != -1);
    }

    public void test_Default_Master_Template392() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;

        r = wc.getResponse(TEST_SERVER + "slave-default");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Master not present", r.toString().indexOf("<title>Using") != -1);
    }

    public void test_Skins_393() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r1 = null, r2 = null, r3 = null;

        r1 = wc.getResponse(TEST_SERVER + "skin?skin=");
        r2 = wc.getResponse(TEST_SERVER + "skin?skin=fancy");
        r3 = wc.getResponse(TEST_SERVER + "skin?skin=plain");

        assertEquals("Status", 200, r1.getResponseCode());
        assertEquals("Status", 200, r2.getResponseCode());
        assertEquals("Status", 200, r3.getResponseCode());

        assert("Neither failed", r1.toString().indexOf("<h1>Sample") != -1);
        assert("Fancy failed", r2.toString().indexOf("bgcolor=\"#FFFFCC\"") != -1);
        assert("Plain failed", r3.toString().indexOf("<h1>Sample") != -1);
    }

    public void test_Fibbonacci_Table_Recursion_394() throws Exception{
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;

        r = wc.getResponse(TEST_SERVER + "fibo-start?m=7");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Level 7 Not Present", r.toString().indexOf("<th  colspan=2  >7") != -1);
        assert("Level 5 Not Present", r.toString().indexOf("<th  colspan=2  >5") != -1);
        assert("Level 3 Not Present", r.toString().indexOf("<th  colspan=2  >3") != -1);
        assert("Level 2 Not Present", r.toString().indexOf("<th  colspan=2  >2") != -1);
    }

    public void test_Templated_If_Tag_388() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;

        r = wc.getResponse(TEST_SERVER + "if");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Check 0", r.toString().indexOf("X is 5") != -1);
        assert("Check 1", r.toString().indexOf("X is not 6") != -1);
        assert("Check 2", r.toString().indexOf("N is \"Fred's Flute\"") != -1);
        assert("Check 3", r.toString().indexOf("N is not \"Fred\"") != -1);
        assert("Check 4", r.toString().indexOf("x is defined") != -1);
        assert("Check 5", r.toString().indexOf("x is nonnil") != -1);
        assert("Check 6", r.toString().indexOf("z is defined") != -1);
        assert("Check 7", r.toString().indexOf("z is nil") != -1);
        assert("Check 8", r.toString().indexOf("w is undefined") != -1);
        assert("Check 9", r.toString().indexOf("w is nil") != -1);
    }

    public void test_Implicit_Tcl_Escape_395() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;

        r = wc.getResponse(TEST_SERVER + "implicit_escape");

        assertEquals("Status", 200, r.getResponseCode());
        assert("X not present", r.toString().indexOf("Qui") != -1);
    }

    public void test_Explicit_Tcl_Escape_396() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;

        r = wc.getResponse(TEST_SERVER + "explicit_escape");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Name not present", r.toString().indexOf("Fred") != -1);
        assert("Name not present", r.toString().indexOf("Ginger") != -1);
        assert("Name not present", r.toString().indexOf("Mary") != -1);
        assert("Name not present", r.toString().indexOf("Sarah") != -1);
        assert("Name not present", r.toString().indexOf("Elmo") != -1);
    }

    public void test_Embedded_Tcl_Escape_401() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;

        r = wc.getResponse(TEST_SERVER + "embed_escape");

        assertEquals("Status", 200, r.getResponseCode());
        assert("X is not 5", r.toString().indexOf("<b>x</b> is indeed 5") != -1);
        assert("Name not present", r.toString().indexOf("giraffe") != -1);
        assert("Name not present", r.toString().indexOf("lion") != -1);
        assert("Name not present", r.toString().indexOf("antelope") != -1);
        assert("Name not present", r.toString().indexOf("fly") != -1);
    }

    public void test_Puts_Inside_Template_402() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        int i;

        r = wc.getResponse(TEST_SERVER + "puts");

        assertEquals("Status", 200, r.getResponseCode());
        assert("X is 4 (check 1)", (i = r.toString().indexOf("x differs from four")) != -1);
        assert("X is 4 (check 2)", r.toString().indexOf("x differs from four", i+1) != -1);
    }

    public void test_ad_page_contract_406() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r1 = null, r2 = null;

        r1 = wc.getResponse(TEST_SERVER + "contract-2?count=2&noun=goose&plural=geese");
        r2 = wc.getResponse(TEST_SERVER + "contract-2?count=13&noun=goose&plural=geese");

        assertEquals("Status", 200, r1.getResponseCode());
        assertEquals("Status", 200, r2.getResponseCode());
        assert("Normal failed", r1.toString().indexOf("geese") != -1);
        assert("Error failed", r2.toString().indexOf("no luck") != -1);
    }

    public void test_Templated_Form_407() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebRequest req = null;
        WebResponse r = null;
        String user_id = null;
        
        r = wc.getResponse(TEST_SERVER + "form");

        WebForm form = r.getForms()[0];

        assertEquals("Status", 200, r.getResponseCode());
        assert("Form not built", form.getParameterValue("user_id") != null);

        user_id = form.getParameterValue("user_id");

        req = form.getRequest();
        req.setParameter("first_name","Test");
        req.setParameter("last_name","User"+user_id);
        req.setParameter("address1","hello");
        req.setParameter("address2","world");
        req.setParameter("city","Atlanta");
        req.setParameter("state","GA");

        r = wc.getResponse(req);

        r = wc.getResponse(TEST_SERVER + "skin?skin=plain");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Insert failed", r.toString().indexOf("User" + user_id) != -1);
    }

    public void test_Templated_Form_Sandwich_Demo_409() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "sandwich?form:id=sandwich&grid=&nickname=yummyfood&protein=bacon&sauce=mayo");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Didn't reload properly", r.toString().indexOf("yummyfood") != -1);
    }

    public void test_Templated_Form_Select_Demo_410() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "select?form:id=car_opts&grid=&extras=windows&payment=atm");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Didn't reload properly", r.toString().indexOf("\"windows\" selected") != -1);
    }

    public void test_Bind_Variables_386() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "bind?user_id=1");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Didn't work", r.toString().indexOf("Fred</td><td>Jones") != -1);
    }

    public void test_Legacy_Tcl_Page_387() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "legacy");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Didn't work", r.toString().indexOf("returns it") != -1);
    }

    public void test_Internal_Comments_389() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "comment");

        assertEquals("Status", 200, r.getResponseCode());
        assert("HTML comment failed", r.toString().indexOf("Page Source") != -1);
        assert("TCL comment failed", r.toString().indexOf("()") != -1);
    }

    public void test_Multiple_Tag_403() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "multiple");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Jones not found", r.toString().indexOf("Jones") != -1);
        assert("Diaz not found", r.toString().indexOf("Diaz") != -1);
    }

    public void test_Multiple_Tag_With_Group_Tag_404() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "group");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Jones not found", r.toString().indexOf("The Jones Family") != -1);
        assert("Diaz not found", r.toString().indexOf("The Diaz Family") != -1);
    }

    public void test_List_Tag_542() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "list");

        assertEquals("Status", 200, r.getResponseCode());
        assert("11! not found", r.toString().indexOf("<li>11! = 39916800") != -1);
    }

    public void test_Installation_Worked_382() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "list");

        assertEquals("Status", 200, r.getResponseCode());
        assert("11! not found", r.toString().indexOf("<li>11! = 39916800") != -1);
    }

    public void test_Display_a_Tcl_File_413() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "show.tcl?file=hello.tcl");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Not working", r.toString().indexOf("ad_page_contract") != -1);
    }

    public void test_Display_a_Compiled_File_414() throws Exception {
        WebConversation wc = ACSCommon.AdminLogin();
        WebResponse r = null;
        
        r = wc.getResponse(TEST_SERVER + "compile.tcl?file=hello.tcl");

        assertEquals("Status", 200, r.getResponseCode());
        assert("Not working", r.toString().indexOf("set __adp_output") != -1);
    }

}
