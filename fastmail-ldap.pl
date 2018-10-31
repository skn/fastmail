#! /usr/bin/perl -TwCS
# Use it with mutt by putting in your .muttrc:
# set query_command = "/home/user/bin/mutt-ldap.pl '%s'"
#
# Then you can search for your users by name directly from mutt. Press ^t
# after having typed parts of the name. Remember to edit configuration
# variables below.
#
# Found at http://www.therandymon.com/files/fastmail-ldap, a modified version
# of script at http://www.bsdconsulting.no/tools/mutt-ldap.pl. Modification
# involved the search criteria so they are compatible with Fastmail's server
#
# 2005-02-24: Fixed for AD/Exchange 2003 & Unicode characters,
# anders@bsdconsulting.no If you find this script useful, let me know. :-)
#
# 2000/2001: Original version obtained from Andreas Plesner Jacobsen at
# World Online Denmark. Worked for me with Exchange versions prior to Exchange
# 2000.
#
# skn: 23-11-2011
#   - Added ability to shown multiple email entries of a contact
#   - Removed $domain var as it was not being used

use strict;
use Encode qw/encode decode/;
use vars qw { $ldapserver $username $password $basedn $attrb @emails $email};

# --- configuration ---
$ldapserver = 'ldaps://ldap.messagingengine.com';
$username = 'cn=USERNAME@fastmail.fm,dc=User';
$password = 'PASSWD';
$basedn = 'dc=AddressBook';
$attrb = 'MULTIMAIL';
#$attrb = 'mail';
# --- end configuration ---

my $search=encode("UTF-8", join(" ", @ARGV));

if (!$search=~/[\.\*\w\s]+/) {
	print("Invalid search parameters\n");
	exit 1;
}

use Net::LDAP;

my $ldap = Net::LDAP->new($ldapserver) or die "$@";

$ldap->bind($username, password=>$password);

my $mesg = $ldap->search (base => $basedn,
                          filter => "(|(|(|(mail=*$search*)(cn=*$search*))(givenName=*$search*))(sn=*$search*))",
			  attrs => [$attrb,'cn']);

$mesg->code && die $mesg->error;

print($mesg->count, " entries found\n");

foreach my $entry ($mesg->all_entries) {
	if ($entry->get_value($attrb)) {
    @emails = $entry->get_value($attrb);
    foreach my $email (@emails) {
      print($email,"\t", decode("UTF-8", $entry->get_value('cn')),"\tFrom LDAP database\n");
    }
  }
}

$ldap->unbind;
