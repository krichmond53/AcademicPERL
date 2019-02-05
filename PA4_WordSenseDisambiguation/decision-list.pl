#!/usr/bin/perl -w
use strict;
use warnings;
use Text::Unidecode;
use Lingua::StopWords qw(getStopWords);

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
##---------------------------------------------------------------------------

my $program = $0;
my $trainFile = $ARGV[0];
my $testFile = $ARGV[1];
my $debug = $ARGV[2];
#print "Input was: $program $trainFile $testFile\n\n";
my %phone;
my %product;

my $trainingFileAsString = getData($trainFile);
my $testingFileAsString = getData($testFile);

getFeatures($trainingFileAsString);  
tagSentence($testingFileAsString);


#--------------------------------------------------------------------
# Using the log-likelihood value, determine the sense of the word 'line' from
# a test file
# Output each sense in the following format:
# <answer instance="line-n.w8_008:13756:" senseid="phone"/> 
#-----------------------------------------------------------------------
sub tagSentence {
  my ($file) = @_;
  my $stopwords = getStopWords('en');
  my @context = split (/<\/context>/, $file);
  my $count = 1;
  my $instanceID="";
  my $prevID;  
  foreach my $text (@context) {
    $prevID = $instanceID;
    $instanceID = "instance" . $1 if $text =~ /instance id(=.+")>/;
#    print "$count) $instanceID\n";
#    $count++;
    if ($prevID eq $instanceID) {
      last;
    }

    my $phoneTotal = 0;
    my $productTotal = 0;
    my @possibleFeatures = split (/ /, $');
    my $features = join ' ', grep { !$stopwords->{$_} } @possibleFeatures;
    my @f = split (/ /, $features);    

    foreach my $i (@f) {
      if (($i =~ /^</) || ($i=~ />$/) || ($i =~ /^\s*$/)) {
#        print "TAG: $i\n";
      } else {
        $i =~ s/[[:punct:]]//g;
        if (!($i =~ /^\s*$/)) {
#            print "FEATURE: $i\n";
            if (exists $phone{$i}) {
#              print "FEATURE: $i is in PHONE. Log-likelihood is $phone{$i}\n";
              $phoneTotal += $phone{$i};
            }
            if (exists $product{$i}) {
#              print "FEATURE: $i is in PRODUCT. Log-likelihood is $product{$i}\n";
              $productTotal += $product{$i};
            }
        }
      }
    }
#    print "Phone-ll = $phoneTotal\nProduct-ll = $productTotal\n";
    if ($phoneTotal > $productTotal) {
      print "<answer $instanceID senseid=\"phone\"/>\n";
    } else {
      print "<answer $instanceID senseid=\"product\"/>\n";
    }
  }
}

#-----------------------------------------------
# Based on the senseid given in the training file, hashes will be created with
# words from the context that can be used to make features and feature vectors
#-------------------------------------------------
sub getFeatures {
  my ($file) = @_;
  my $sense;
  my $stopwords = getStopWords('en');
  my @context = split (/<\/context>/, $file);
  my %phoneFeatures;
  my %productFeatures;
  my %allFeatures;

  foreach my $text (@context) {
    if ($text =~ /\bsenseid="phone"/) {
#      print "\nPHONE\n $text\n\n";

      my @possibleFeatures = split (/ /, $');

      my $features = join ' ', grep { !$stopwords->{$_} } @possibleFeatures;
      my @f = split (/ /, $features);    


      foreach my $i (@f) {
        if (($i =~ /^</) || ($i=~ />$/) || ($i =~ /^\s*$/)) {
#          print "TAG: $i\n";
        } else {
          $i =~ s/[[:punct:]]//g;
          if (!($i =~ /^\s*$/)) {

#            print "FEATURE: $i\n";
            $phoneFeatures{$i}++;     
            $allFeatures{$i}++;
          }
        }
      }

    } elsif ($text =~ /\bsenseid="product"/) {
#      print "\nPRODUCT\n $text\n\n";
      my @possibleFeatures = split (/ /, $');

      my $features = join ' ', grep { !$stopwords->{$_} } @possibleFeatures;
      my @f = split (/ /, $features);    


      foreach my $i (@f) {
        if (($i =~ /^</) || ($i=~ />$/) || ($i =~ /^\s*$/) ) {
#          print "TAG: $i\n";
        } else {
          $i =~ s/[[:punct:]]//g;
          if (!($i =~ /^\s*$/)) {

#            print "FEATURE: $i\n";
            $productFeatures{$i}++;     
            $allFeatures{$i}++;
          }
        }
      }

    }

  }
  open(my $fh, '>', $debug);
  print $fh "Sense 1, Sense 2, Total Words, P(sense1), P(sense2), Log-Likelihood, SENSE\n";
  foreach my $feature (sort { $allFeatures{$a} <=> $allFeatures{$b} } keys %allFeatures){
  my $s1=0;
  my $s2=0;
  my $wordCt;

## IF THE FEATURE EXISTS IN BOTH PRODUCT AND PHONE    
    if ((exists $phoneFeatures{$feature}) && (exists $productFeatures{$feature})){
#      printf("%-20s Phone: %-5s Product: %-5s Total: %-5s\n", $feature, $phoneFeatures{$feature}, $productFeatures{$feature}, $allFeatures{$feature});
      $s1 = $phoneFeatures{$feature};
      $s2 = $productFeatures{$feature};
      $wordCt = $allFeatures{$feature};
      if ($s1 > $s2) {
        $sense = "PHONE";
      } else {
        $sense = "product";
      }

## IF THE FEATURE EXISTS ONLY IN PHONE
    } elsif ((exists $phoneFeatures{$feature}) && (!(exists $productFeatures{$feature}))){
#      printf("%-20s Phone: %-5s Product: %-5s Total: %-5s\n", $feature, $phoneFeatures{$feature}, 0, $allFeatures{$feature});
      $s1 = $phoneFeatures{$feature};
      $wordCt = $allFeatures{$feature};
      $sense = "PHONE";

## IF THE FEATURE EXISTS ONLY IN PHONE
    } else {
#      printf("%-20s Phone: %-5s Product: %-5s Total: %-5s\n", $feature, 0, $productFeatures{$feature}, $allFeatures{$feature});
      $s2 = $productFeatures{$feature};
      $wordCt = $allFeatures{$feature};
      $sense = "product";
    }
    
    my $ps1 = ($s1+1)/($wordCt+2);  # Using Laplace smoothing V = 2 for 2 senses
    my $ps2 = ($s2+1)/($wordCt+2);
    my $ll = abs(log($ps1/$ps2));

    print $fh "$s1, $s2, $wordCt, $ps1, $ps2, $ll, $sense\n";
    #print "PS1 = $ps1\t\tPS2 = $ps2\n\n";
#    printf("\nFeature: %-15s\n\tLog-likelihood: %.4f of %-8s\n", $feature, $ll, $sense);
    
    if ($sense eq "product") {
      $product{$feature} = $ll;
    } else {
      $phone{$feature} = $ll;
    }
  }

  foreach my $ft (sort {$phone{$a} <=> $phone{$b}} keys %phone){
#    printf("%-20s Log-likelihood %.4f\n", $ft, $phone{$ft});
  }
  foreach my $ft (sort {$product{$a} <=> $product{$b}} keys %product){
#    printf("%-20s Log-likelihood %.4f\n", $ft $product{$ft});
  }
}




#--------------------------------------------
# Open file and make it a single string.
#-------------------------------------------
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

