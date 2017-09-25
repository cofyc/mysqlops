#!/usr/bin/perl -w
#
# This script is used to generate MySQL configuration file.
#

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage);
use File::Basename;

my $this_script = basename($0);
my $option_help = '';
my $option_data_dir = '';
my $option_password = '';
my $option_bind_address = '';
my $option_mode = '';
