#!/usr/bin/perl 
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2020] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use FindBin qw($Bin);
use File::Path;
use File::Basename qw( dirname );
use Getopt::Long;
use Pod::Usage;

=head1 USAGE

Dryrun copy everything to live:

copy_files_to_websites.pl --release=101-48 --site=live --dryrun

Copy everything to staging:

copy_files_to_websites.pl --release=101-48 --site=staging

Copy plants species content only to your local checkout (ensembl-static must be at same level as eg-web-plants):

copy_files_to_websites.pl --release=101-48 --division=plants --species-only

=cut

my ($SCRIPT_ROOT, $help, $verbose, $dryrun, $version, $release, $site, $division, $home_only, $species_only);

BEGIN{
  &GetOptions(
              'help|h'          => \$help,
              'verbose|v'       => \$verbose,
              'dryrun|d'        => \$dryrun,
              'release|r=s'     => \$release,
              'site:s'          => \$site,
              'division|div:s'  => \$division,
              'home-only:s'     => \$home_only,
              'species-only:s'  => \$species_only,
  );

  pod2usage(1) if $help;

  $SCRIPT_ROOT = dirname( $Bin );
}

my ($version, $eg_version) = split('-', $release);

unless ($version && $eg_version) {
  die "Please provide an Ensembl version and an NV release number, separated by a hyphen, e.g. '--release=101-48'.\n";
}

## Default to all divisions
my @divisions = $division ? ($division) : qw(bacteria fungi metazoa plants protists);

## Set destination - defaults to local checkout(s) in same directory as this repo
my ($OUT_ROOT, $OUT_DIR, $division_string);

if ($site) {
  if ($site !~ /staging|test|live/) {
    die "Please set the destination as either staging or live. Note that test sites use the live checkouts for the upcoming release.\n";
  }
  $site = 'live' if $site eq 'test';
  $OUT_ROOT = "/nfs/public/release/ensweb/$site";
  $division_string = join('|', @divisions)."/www_$version";
}
else {
  if (!$division) {
    die "At the moment you can only make a local copy of content for one division at a time. Please specify a division on the command line.\n";
  }
  ($OUT_ROOT = $SCRIPT_ROOT) =~ s#/ensembl-static##;
  $division_string = "eg-web-$division";
}

print "Copying files into $OUT_ROOT/$division_string...\n\n";

## TODO - check that ensembl-static is on same branch as desired eg-version 

## Define input directories for each type of content
my $home_text_in  = '';
my $home_img_in   = '/images';
my $sp_text_in    = '/species';
my $sp_img_in     = '/species/images';

## Define output directories for each type of content
my $home_text_out = 'htdocs/ssi';
my $home_img_out  = 'htdocs/img';
my $sp_text_out   = 'htdocs/ssi/species';
my $sp_img_out    = 'htdocs/i/species';
my ($input_dir, $output_dir);

foreach my $div (@divisions) {
  print "Copying $div files...\n\n";

  my $div_in_dir     = $SCRIPT_ROOT.'/'.$div;
  my $div_out_dir    = $site ? sprintf('%s/www_%s', $OUT_ROOT, $version) : $OUT_ROOT;
  $div_out_dir      .= "/eg-web-$div/";

  ## Copy home content
  unless ($species_only) {
    ## Text files
    $input_dir  = $div_in_dir.$home_text_in;
    $output_dir = $div_out_dir.$home_text_out;
    copy_files($input_dir, $output_dir);

    ## Images
    $input_dir  = $div_in_dir.$home_img_in;
    $output_dir = $div_out_dir.$home_img_out;
    copy_files($input_dir, $output_dir);

    print "Copied home content\n";
  }

  ## Copy species content
  unless ($home_only) {
    ## Text files
    $input_dir  = $div_in_dir.$sp_text_in;
    $output_dir = $div_out_dir.$sp_text_out;
    ## Note that we recurse into subdirectories for this one, as there are a lot of these files!
    copy_files($input_dir, $output_dir, 1);

    ## Images
    $input_dir  = $div_in_dir.$sp_img_in;
    $output_dir = $div_out_dir.$sp_img_out;
    copy_files($input_dir, $output_dir);

    print "Copied species content\n";
  }

}

sub copy_files {
  my ($in, $out, $recurse) = @_;

  my $cmd = "cp $in/* $out";
  print "Executing $cmd\n" if $verbose;
  system($cmd) unless $dryrun;

  if ($recurse) {
    $cmd = "cp $in/*/* $out";
    print "Executing $cmd\n" if $verbose;
    system($cmd) unless $dryrun;
    $cmd = "cp $in/*/*/* $out";
    print "Executing $cmd\n" if $verbose;
    system($cmd) unless $dryrun;
  }

}

print "\nDone!\n\n";


