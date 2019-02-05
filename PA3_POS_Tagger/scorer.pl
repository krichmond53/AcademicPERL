#!/usr/bin/perl -w
use strict;
use warnings;
use Text::Unidecode;
use List::Util qw(first max);
use List::Util qw(reduce);
use Text::Table;

#---------------------------------------------
# Kevin Richmond - March 2018
# CMSC 416 - Natural Language Processing
# Programming Project 3 - POS Tagger, scoring utility program
#   Problem - Given a pre-tagged text file, we want to be able to determine 
#   what part of speech each word is.  Using these word tags, other documents
#   should be able to be recognize these words and tag them based on what part
#   of speech it is.
#   
#   Example Input - 
#   [ Pierre/NNP Vinken/NNP ]
#   ,/, 
#   [ 61/CD years/NNS ]
#   old/JJ ,/, will/MD join/VB 
#   [ the/DT board/NN ]
#   as/IN 
#   [ a/DT nonexecutive/JJ director/NN Nov./NNP 29/CD ]
#   ./. 
#   [ Mr./NNP Vinken/NNP ]
#   is/VBZ 
#   [ chairman/NN ]
#   of/IN 
#   [ Elsevier/NNP N.V./NNP ]
#   ,/, 
#   [ the/DT Dutch/NNP publishing/VBG group/NN ]
#   ./. 
#   [ Rudolph/NNP Agnew/NNP ]
#   ,/, 
#   [ 55/CD years/NNS ]
#   old/JJ and/CC 
#   [ former/JJ chairman/NN ]
#   of/IN 
#   [ Consolidated/NNP Gold/NNP Fields/NNP PLC/NNP ]
#   ,/, was/VBD named/VBN 
#   [ a/DT nonexecutive/JJ director/NN ]
#   of/IN 
#   [ this/DT British/JJ industrial/JJ conglomerate/NN ]
#   ./. 
#
#   Example Output -
#
#     CC   CD   DT   EX FW IN   JJ   JJR JJS LS MD  NN   NNP  NNPS NNS  PDT 
#     CC   1286    0    0  0  0    0    0   0   0 0    0    2    0  0      0
#     CD      0 1474    0  0  0    0    3   0   0 4    0    6    3  0      6
#     DT      8    0 4747  0  0    4    0   0   0 0    0    0    5  0      0
#     EX      0    0    0 57  0    0    0   0   0 0    0    0    0  0      0
#
#   Algorithm Description - First the training data file needs to be brought in,
#   parsed into the word/tag pairs, and any extraneous characters such as square
#   brackets would be removed. Next, each pair would be counted.  Since we are
#   trying to use only the maximal word tag of a particular word, the original
#   hash containing the word tag pair would have any occurrence of that word 
#   removed if it was not the tag which happened the most for that word.
#
#   After the training data has been broken down into a list of maximal word 
#   tags, the test file would need to be brought it.  Again, this would be parsed
#   into word/tag pairs and any extraneous characters would be removed. Finally,
#   the test file would be tagged based on the maximal tags found in the training
#   file.  If the word was not found in the training file, it is assumed to have
#   the tag NN.  
#
#   5 rules were to be created in order to increase the accuracy of our POS 
#   tagging.  I found that checking for suffixes and capital letters when the tags
#   were unknown gave better accuracy than just tagging every unknown as NN.
#   The results of the rules added are listed below.
#
#   Accuracy without any rules: 81.79%
#   Rule 1: If unknown word ends in s, assume it is NNS not NN
#       New Accuracy: 83.26%
#   Rule 2: If unknown word ends in ed, assume it is VBD not NN
#       New Accuracy: 83.21%
#   Rule 3: If unknown word ends in ing, assume it is VBG not NN
#       New Accuracy: 83.21%
#   Rule 4: If unknown word ends in ive, assume it is JJ not NN
#       New Accuracy: 81.81%
#   Rule 5: If first letter is capitalized, assume it is NNP not NN
#       New Accuracy: 86.37%
#   All rules at the same time accuracy: 88.20%
#
#---------------------------------------------------------------------------

my $program = $0;
my $myFile = $ARGV[0];
my $keyFile = $ARGV[1];

#print "Input was: $program $trainFile $testFile\n\n";

my $testFile = getData($myFile);
my $gold = getData($keyFile);
$gold = clean($gold);
my @allTags = findAllTags($gold);
my $tagCount = @allTags;

my %findings = compareFiles($testFile, $gold);
my %pureData = removeNonTags(\%findings, @allTags);

makeChart(\%pureData, @allTags);

#--------------------------------------
# Create confusion matrix
#--------------------------------------
sub makeChart {
  my ($data, @tags) = @_;
  my %hash = %$data;
  my @sortedTags = sort { ($a) cmp ($b) } @tags;
  my $len = @sortedTags;
  my %temp;
  my $valCount;
  my $correctTag;
  my $taggedCorrect;
  my $taggedWords;
  my $tb = Text::Table->new(
      " ",@sortedTags#"Planet", "Radius\nkm", "Density\ng/cm^3"
      );

# FIND ALL KEYS IN HASH WHO HAS TAG AS THEIR SUBSTRING
  for (my $i=0; $i<$len; $i++) 
  {
    my %temp;
    my @values = ();
    for (grep /^\Q$sortedTags[$i]\E [A-Z]*$/, keys %hash) 
    {
      $temp{$_} = $hash{$_};
#      print "$_ contains $sortedTags[$i] (value: $hash{$_})\n";
    }
    @values[0] = $sortedTags[$i];

    foreach (sort keys %temp) 
    {
      $taggedWords += $temp{$_};            # Count number of words which have been tagged
      $correctTag = $1 if  $_ =~ /[A-Z]+ ([A-Z]+)/;
#      printf("%-10s: %-10s ---> %-15s\n",$_, $temp{$_}, $correctTag);
      if ($sortedTags[$i] eq $correctTag) {
        $taggedCorrect += $temp{$_};
      } 
      
      for (my $j=1; $j<=$len; $j++) 
      {
        if (($sortedTags[$j-1] eq $correctTag) && ((!$values[$j]) || ( $values[$j] = 0 ))) 
        {
#          print "$correctTag equals $sortedTags[$j-1]\n";
          $values[$j] = $temp{$_};
        } 
        else
        {
          if (!$values[$j])
          {
          $values[$j] = 0;
          }
        }
      }
    }
=cut    
    foreach (@values) {
      printf("%-5s",$_);
    }
=cut  
    $tb->add(@values);
  }

  print $tb;
  print "Total correctly tagged words: $taggedCorrect\n";
  print "Total number of tagged words: $taggedWords\n";
  my $accuracy = $taggedCorrect/$taggedWords;
  print "Total accuracy: $accuracy\n";
}

#----------------------------------------------------------------------
# Where there are keys or values that are not actual tags, remove them
#----------------------------------------------------------------------
sub removeNonTags {
  my ($data, @tags) = @_;
  my %hash = %$data;
  my %validTags = map {$_=>1} @tags;
  my $count = 0;
  my %clean;

  foreach (sort keys %validTags) 
  {
#    printf("%-10s: %-10s\n",$_, $validTags{$_});
    
    my $thisTag = $_;
    for (grep /\b\Q$thisTag\E\b/, keys %hash) 
    {
#      print "$_ \tcontains $thisTag (value: $hash{$_})\n";
      if ($_ =~ /^[A-Z0-9\.? ]*$/) 
      { 
        $clean{$_} = $hash{$_};
      }
    }
  }
  return %clean;
}

#-------------------------------------------
# Compare output with key files
#-----------------------------------------
sub compareFiles {
  my ($test, $gold) = @_;
  my $l = 0;
  my %results;

  my @t1 = split (/ /, $test);
  my @g1 = split (/ /, $gold);
  my $t1size = @t1;
  my $g1size = @g1;
#  print "$t1size vs $g1size\n";

  for (my $i=0; $i<$g1size; $i++) 
  {
    my @testSet = split (/\//, $t1[$i]);
    my $tlen = @testSet;
    my @goldSet = split (/\//, $g1[$i]);
    my $glen = @goldSet;
    
    if ($tlen == $glen) 
    {
      $l = $glen-1;
    }
    my $tagMatch = $testSet[$l] . " " . $goldSet[$l];
    $results{$tagMatch}++;
  }
  return %results;
}

#-----------------------------------------
# Parse out all actual POS tags from key
#----------------------------------------
sub findAllTags {
  my ($data) = @_;
  my %t;
  my $tc = 0;
  my @tags;

  my @pairs = split (/ /, $data);
  foreach my $word (@pairs)
  {
    my $tag = $word;
    $tag =~ /\b.+\/([A-Z]+)\b/;
    $t{$1} = 0;
    
  }
  foreach my $key (keys %t)
  {
    $tags[$tc] = $key;
    $tc++;
  } 
  return @tags;
}

#--------------------------------------------
# Remove brackets and occurrences of more than 1 space
#----------------------------------------------------
sub clean {
  my ($data, %hash) = @_;
  my $str = $data; 

  $str =~ s/[\[\]]//g;
  $str =~ s/\s+/ /g;
  return $str;
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































