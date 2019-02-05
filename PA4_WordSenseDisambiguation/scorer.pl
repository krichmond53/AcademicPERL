#!/usr/bin/perl -w
use strict;
use warnings;
use Text::Unidecode;
use Text::Table;

#---------------------------------------------
# Kevin Richmond - March 2018
# CMSC 416 - Natural Language Processing
# Programming Project 4 - Word Sense Disambiguation
# 
# Problem: In the English language, there are words with more than one sense or
#   meaning.  For a computer to be able to understand the difference between one
#   sense and another, it must be able to gather from its surrounding context 
#   which sense best fits the word.
#
# Example input:
#
#   <instance id="line-n.w9_10:6830:">
#   <answer instance="line-n.w9_10:6830:" senseid="phone"/>
#   <context>
#    <s> The New York plan froze basic rates, offered no protection to Nynex against an economic downturn that sharply cut demand and didn't offer flexible pricing. </s> <@> <s> In contrast, the California economy is booming, with 4.5% access <head>line</head> growth in the past year. </s> 
#    </context>
#    </instance>
#
# Example output:
#   Phone Product Total % Correct        
#   Phone   67     5      72     93.0555555555556
#   Product  0    54      54    100              
#
#   % ERROR        Phone              Product          
#   Phone   0.0694444444444444 0.138888888888889
#   Product 0                  0                
#
#   Total correctly tagged senses: 121
#   Total number of tagged senses: 126
#   Total accuracy: 0.96031746031746
#   Out of 126 tags, the most frequence sense (phone) is tagged 72 times.
#   Therefore, the MFS baseline 0.571428571428571
#   Total accuracy increase is 0.388888888888889
#        
# Description of Algorithm:
#   In order for the machine to learn context, it must first receive some data to
#   be trained on.  Therefore, a training file was taken in by the program via
#   command line, parsed to collect the context data, then each word of the data
#   was counted to see how often it occurred based on a sense of the word 'line'.
#   There were 2 senses that were being determined, that of a phone line and a 
#   production line.
#   
#   Depending on which sense was given by the training data, the associated 
#   context words were added to separate hashes. Each hash represents a feature
#   vector where each associated word is a feature. A third hash was created 
#   with all the features of both senses in order to calculate the log-likelihood
#   of each feature. 
#
#   A test file was taken in also via command line which did not contain any 
#   sense tags.  Based on the log likelihood values determined from the
#   training data, the sense of each instance in the test file was determined
#   by summing and then printed to STDOUT.  The results were then put through
#   scorer.pl which determines the accuracy of my results verses the baseline
#   results.
#
#---------------------------------------------------------------------------

my $program = $0;
my $myFile = $ARGV[0];
my $keyFile = $ARGV[1];

#print "Input was: $program $myFile $keyFile\n\n";

my $testFile = getData($myFile);
my $gold = getData($keyFile);

my %results = compareFiles($testFile, $gold);

makeChart(\%results);
#--------------------------------------
# Create confusion matrix from the hash with 4 possible outcomes, then perform
# calculations to be displayed
#--------------------------------------
sub makeChart {
  my ($data) = @_;
  my %hash = %$data;
  my $correctPhone=0;
  my $wrongPhone=0;
  my $totalPhone=0;
  my $wrongProduct=0;
  my $correctProduct=0;
  my $totalProduct=0;


  if (exists $hash{Product}) {
#    print "Guessed PRODUCT correctly $hash{Product} times\n";
    $correctProduct = $hash{Product};
  }
  if (exists $hash{Phone}) {
#    print "Guessed PHONE correctly $hash{Phone} times\n";
    $correctPhone = $hash{Phone};
  }
  if (exists $hash{xPhone}) {
#    print "Guessed PRODUCT, actual PHONE $hash{xPhone} times\n";
    $wrongPhone = $hash{xPhone};
  }
  if (exists $hash{xProduct}) {
#    print "Guessed PHONE, actual PRODUCT $hash{xProduct} times\n";
    $wrongProduct = $hash{xProduct};
  }
  
  $totalPhone = $correctPhone+$wrongPhone;
  $totalProduct = $correctProduct+$wrongProduct;
  my $grandTotal = $totalPhone+$totalProduct;
  my $tb = Text::Table->new(
      " ","Phone","Product","Total","% Correct"     #"Planet", "Radius\nkm", "Density\ng/cm^3"
      );
  
  $tb->add("Phone", $correctPhone, $wrongPhone, $totalPhone,($correctPhone/$totalPhone*100));
  $tb->add("Product", $wrongProduct, $correctProduct, $totalProduct,($correctProduct/$totalProduct*100));
  
  my $tb2 = Text::Table->new(" ","Phone","Product");
  $tb2->add("Phone", 1-($correctPhone/$totalPhone), 1-(($correctPhone-$wrongPhone)/$totalPhone));
  $tb2->add("Product", 1-($correctProduct/$totalProduct), 1-(($correctProduct-$wrongProduct)/$totalProduct));

  print $tb, "\n% ERROR";
  print $tb2;
  my $taggedCorrect = $correctPhone+$correctProduct;
  my $totalTagged = $taggedCorrect+$wrongPhone+$wrongProduct;
  my $accuracy = $taggedCorrect/$totalTagged;
  my $mfs = $totalPhone/$totalTagged;
  print "\nTotal correctly tagged senses: $taggedCorrect\n";
  print "Total number of tagged senses: $totalTagged\n";
  print "Total accuracy: $accuracy\n";
  print "Out of $totalTagged tags, the most frequence sense (phone) is tagged $totalPhone times.\nTherefore, the MFS baseline $mfs\n";
  my $increase = $accuracy-$mfs;
  print "Total accuracy increase is $increase\n";
}


#-------------------------------------------
# Compare output with key file and create a hash of the 4 possible results
# - Guessed phone correctly/incorrectly and guessed product correctly/incorrectly
#-----------------------------------------
sub compareFiles {
  my ($test, $gold) = @_;
  my $l = 0;
  my %results;

  my @t1 = split (/\/>/, $test);
  my @g1 = split (/\/>/, $gold);
  my $t1size = @t1;
  my $g1size = @g1;
#  print "$t1size vs $g1size\n";

  for (my $i=0; $i<$g1size; $i++) 
  {
    if ($t1[$i] eq $g1[$i]) 
    {
      if ($t1[$i] =~ /phone/) {
#        print "Matched $t1[$i] for PHONE.\n";
        $results{Phone}++;
      } elsif ($t1[$i] =~ /product/) {
#        print "Matched $t1[$i] for PRODUCT.\n";
        $results{Product}++;
      } 


    } else {
      if ($g1[$i] =~ /phone/) {
#        print "Guessed PRODUCT, actual $g1[$i]\n";
        $results{xPhone}++;
      } elsif ($g1[$i] =~ /product/) {
#        print "Guessed PHONE, acutal $g1[$i]\n";
        $results{xProduct}++;
      } 
    }

  }
  foreach my $j (keys %results) {
#    print "$j\t$results{$j}\n";
  }

  return %results;
}


#---------------------------------------------
# Open file and make it a big string.
#---------------------------------------------
sub getData {
  my ($file) = @_;
  my $bigString = "";

  if (open(my $text, '<:encoding(UTF-8)', $file))
  {
    while (my $str = <$text>) 
    
    {
      chomp $str;
      $bigString .= $str . " ";
    }
  }
  else
  {
    warn "Could not open file '$file'.\n$!";
  }
  return $bigString;
}































