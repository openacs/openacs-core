ad_library {
  Server startup initialization code for the acs-automated-testing package

  @author Peter Marklund
  @creation-date 4:th of April 2003
  @cvs-id $Id$
}

#
# Set the valid testcase categories list, and testcase/component lists.
#
nsv_set aa_test cases {}
nsv_set aa_test components {}
nsv_set aa_test init_classes {}
nsv_set aa_test categories {config db script web}
