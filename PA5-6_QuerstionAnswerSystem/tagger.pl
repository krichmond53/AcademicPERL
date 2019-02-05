#!/usr/bin/perl -w
use strict;
use warnings;
use Text::Unidecode;
use List::Util qw(first max);
use List::Util qw(reduce);


#---------------------------------------------
# Kevin Richmond - March 2018
# CMSC 416 - Natural Language Processing
# Programming Project 3 - POS Tagger
#
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
##---------------------------------------------------------------------------

my $program = $0;
my $trainFile = $ARGV[0];
my $testFile = $ARGV[1];

#print "Input was: $program $trainFile $testFile\n\n";

my $trainingFileAsString = getData($trainFile);
my $pairs = getWordsAndTags($trainingFileAsString);
my %wordsAndMaxTags = getWordMaxTags($pairs);
my $testingFileAsString = getData($testFile);
tagTestData($testingFileAsString, %wordsAndMaxTags);

#------------------------------------------------------------
# Using the word/tags from the training data, the test data is tagged.
#-------------------------------------------------------------
sub tagTestData {
  my ($data, %hash) = @_;
  my $str = $data; 

  $str =~ s/[\[\]]//g;
  $str =~ s/\s+/ /g;
  my $prevWord; 
  my @toBeTagged = split (/ /, $str);
  my $len = @toBeTagged;

  for (my $i=0; $i<$len; $i++)
  {
    my $word = $toBeTagged[$i];
    if ($i > 1)
    { 
      $prevWord = $toBeTagged[$i-1];
    }
    
    my $lastLetter = substr($word, -1);
    my $lastTwoLetters = substr($word, -2);
    my $lastThreeLetters = substr($word, -3);
    my $firstLetter = substr($word, 0, 1);
    if (exists $hash{$word})
    {
      print "$word/$hash{$word} ";
    }
    elsif ($firstLetter =~/[A-Z]/)  # Rule 5: If first letter of unknown is uppercase, make tage NNP instead of NN
    {
      print "$word/NNP ";
    }
    elsif ($lastThreeLetters eq "ive")  # Rule 4: If last 4 letters of unknown are 'ive', make tag JJ instead of NN
    {
      print "$word/JJ ";
    }
    elsif ($lastThreeLetters eq "ing")  # Rule 3: If last 3 letters of unknown are 'ing', make tag VBG instead of NN
    {
      print "$word/VBG ";
    }
    elsif ($lastTwoLetters eq "ed")     # Rule 2: if last two letters of unknown are 'ed', make tag VBD instead of NN 
    {
      print "$word/VBD ";
    }
    elsif ($lastLetter eq "s")          # Rule 1: if last letter of unknown is 's', make tag NNS instead of NN
    {
      print "$word/NNS ";
    }
    else
    {
      print "$word/NN ";
    
    }
  }
  print "\n";
}

#------------------------------------------------------------------
# Compare the words which have multiple tags, determine which tag is used
# the most for each tag, and put that into a new maximized hash table
#-------------------------------------------------------------------
sub getWordMaxTags {
  my ($data) = @_;
  my @pair = split (/ /, $data);
  my %wtCount;
  my %tagSet;
  
  $wtCount{$_}++ foreach @pair;     # Make hash w/ Key=pair and value=times seen
  my $hashSize = keys %wtCount;

  while ($hashSize > 0) 
  {

# List::Util::reduce finds the max value in a hash.
    my $maxTag = List::Util::reduce { $wtCount{$b} > $wtCount{$a} ? $b :$a } keys %wtCount;

    my @word = split (/\//, $maxTag);
    if (exists $tagSet{$word[0]}) 
    {
#      print "**** \"$word[0]\" already exists\n";
      delete($wtCount{$maxTag});
      $hashSize--;
    }
    else 
    {
#      print "Adding \"$maxTag\" to tagSet.\t Found $wtCount{$maxTag} times\n";
      $tagSet{$word[0]} = $word[1];
      delete($wtCount{$maxTag});
      $hashSize--;
    }
  }
  return %tagSet;
}

#--------------------------------------------------------------------
# This subroutine takes the input file as a single string, splits it based on 
# spaces, and then creates a string of only the word/tag pairs and removes
# brackets that are not helpful
#-------------------------------------------------------------------
sub getWordsAndTags {
  my ($data) = @_;
  
  my @s = split (/ /, $data);
  my $len = @s;
  my $bigram = "";


  for (my $i = 0; $i<$len; $i++)
  {
    if (($s[$i] =~/\b\w+\p{P}?\/[A-Z]+\b/g)  || ($s[$i] =~/([^\s]+)\/\1/)) 
    {
      $bigram .= $s[$i] . " ";
    }
  }

  return $bigram;
}

#--------------------------------------------
# Open file and make it a big string.
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

