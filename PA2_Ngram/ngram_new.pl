#!/usr/bin/perl -w
use strict;
use warnings;
use Text::Unidecode;
#use Switch;           # Switch cases made things a lot easier

#---------------------------------------------
# Kevin Richmond
# CMSC 416 - Natural Language Processing
# Programming Project 2 - n-grams
#
# Problem: We want to be able to know how often certain phrases are used from a
# plain text file in order to make sentences with a similar conversational tone
# to them
#
# SAMPLE INPUT: ./ngram.pl 1 10 test.txt  
#
# SAMPLE OUTPUT:
#
# krichmond53 PERL Projects $ 
#
# This program by Kevin Richmond generates random sentences based on an n-gram model.
#
# Command line settings: ./ngram.pl 1 10
# Using an 1-gram model, produce 10 random sentences.
#
# Sentence 1: Was to him god darkness there was darkness darkness through overcome with to to and came was was made came bear bear.
#
# Sentence 2: The and and.
#
# Sentence 3: Any him about a was god was the witness he.
#
# Sentence 4: Might light he with through made the him.
#
# Sentence 5: Name might through from light sent light.
#
# Sentence 6: Witness was.
#
# Sentence 7: Witness in.
#
# Sentence 8: God the god made him god the not that life made and through not the light he and might it a with the.
#
# Sentence 9: To the was there.
#
# Sentence 10: Was word all the shines and word about the the were bear the light to darkness light about a.
#
#
# Number of files: 1
# Number of strings: 9
# Total words: 140
#
# ALGORITHM:
#   1. Parse the command line arguments in order to extract n (the n-gram #), m (the number of sentence to be randomly generated, and the name of the text files to be used for the sentence generation model.
#   2. Create an array of strings from the files input.
#   3. Add spaces for punctuation so that they can be added to the model
#   4. Based on n, break down each sentence into groups of that many words, overlapping where n > 1.
#   5. Store the ngrams and their occurrences in a hash table
#   6. Based on the ngram requested, find the probability of a certain phrase based on the formula P(f|e) = freq(f|e)/freq(e) where e is the probability of the word or phrase occurring in the n-1gram and f is the frequency of the word or phrase in the n-gram model
#   7. The probability of a phrase along with the phrase would be stored in a new hash.
#   8. The new hash would be sorted from low-to-high where all the probabilities would add up to 1.
#   9. A random number would be generated.  If that number was less than or equal to one of the key values (probabilities) in the hash, that word or phrase would be used to start constructing a sentence.
#   10. This continues until punctuation is selected by the random number, which causes the sentence to end.
#   11.  This process is repeated until m number of sentences have been produced based on the ngram model's probability.
#
#---------------------------------------------------------------------------

#-------------------------------------------------------------------------
# Acquire all command line arguments.  There are at least 3 required:
# n = (integer) number of words for the n-gram model
# m = (integer) number of sentences to generate as output
# *.txt = name of text file(s) to be analyzed by the n-gram model. The number of
# text files to be read-in is 1 or more and will be separated by a space.
#--------------------------------------------------------------------------

my $progName = $0;
my $n = $ARGV[0];
my $m = $ARGV[1];
my $inLen = @ARGV;
my $fileCount = 0;
my $bookStr = "";
my @strings = [];
my @strings2 = [];
my $strLen = 0;
my %wordCount;
my $totalWords = 0;
my %library;
my @gramValue;

print "\nThis program by Kevin Richmond generates random sentences based on an n-gram model.\n";
print "\nCommand line settings: $progName $n $m\nUsing an $n-gram model, produce $m random sentences.\n\n";

for (my $i=2; $i<$inLen; $i++){
  $bookStr = parseFile($ARGV[$i]);

  if ($n == 1) {
    @strings = makeGramable($bookStr, $n);
    unigram(@strings);
  } 
  elsif ($n == 2) {
    @strings = makeGramable($bookStr, $n);
    multigram(@strings);
    #$n--;
    print "\n\n";
    #$n++;
    @strings2 = makeGramable($bookStr, ($n));
    unigram(@strings2);
  } 
  elsif ($n > 2) {
    @strings = makeGramable($bookStr, $n);
    multigram(@strings, %wordCount);
    #$n--;
    print "\n\n";
    @strings2 = makeGramable($bookStr, ($n));
    #$n++;
    ngram(@strings2, %library);
  } 
  else {
    print "Not a valid n-gram request.\n";
  }
=cut
  while( my( $key, $value ) = each %wordCount ){
    print "--> WC$n\t $key : $value\n";
  }
  while( my( $key, $value ) = each %library ){
    print "--> WC$n\t $key : $value\n";
  }


  foreach my $key (sort { $wordCount{$b} <=> $wordCount{$a} } keys %wordCount) {
    #printf "--> WC$n\t $key : $wordCount{$key}\n"; # $wordCount{$key}, $key;
    print "\n"; $n++;
  }
  foreach my $key (sort { $library{$b} <=> $library{$a} } keys %library) {
    #printf "--> WC$n\t $key : $library{$key}\n"; # $wordCount{$key}, $key;
    $n--;
  }
=cut
  $strLen += @strings;
  $strLen += @strings2;
  $fileCount++;
}

#--------------------------------------------------------
# Output requires informative text as first line including what the program is,
# who the author is, and what it is doing.  It must also output the command line
# options followed by the m sentences generated by the program.
#--------------------------------------------------------

senGen($m);
print "\nNumber of files: $fileCount\n";
print "Number of strings: $strLen\n";
print "Total words: $totalWords\n";


#------------------------------------------------------------
# Make a unigram hash
#-----------------------------------------------------------
sub unigram {
  my (@w) = @_;
  my $thisKey;
  my $count;

  foreach my $i (0 .. $#strings){

# Split each sentence by white-space, removing it
    my @w = split /\s+/, $strings[$i];

    foreach my $j (0 .. $#w){
      if (exists$wordCount{$w[$j]}){
        $wordCount{$w[$j]}++;
#print "$w[$j] = $wordCount{$w[$j]}\n";
        $count++;

      } else {
        $wordCount{$w[$j]} = 1;
#print "$w[$j] = $wordCount{$w[$j]}\n";
        $count++;
      }
    }
  }
  if ($totalWords == 0) {
    $totalWords = $count;
  } 
#   @words = sort {$wordCount{$b} <=> $wordCount{$a}} keys %wordCount;
  
}
#-------------------------------------------------------------
# Make a multigram hash
#-------------------------------------------------------------
sub multigram {
  my (@w) = @_;
  my $thisKey;
  my $count = 0;

  foreach my $i (0 .. $#strings){

# Split each sentence by white-space, removing it
    my @w = split /\s+/, $strings[$i];

    my $size = $n-1;
    foreach my $k (0 .. $#w-$size)
    {
      my $ngram = $w[$k] . " ";
      for (my $i=1; $i<=$size; $i++) 
      {
        if ($i != $size) {
          $ngram .= $w[$k+$i] . " ";
        } else {
          $ngram .= $w[$k+$i] . " ";  
        }
      }  

      $library{$ngram}++;
#      print ">>>> $n-gram: \"$ngram\" occurs $library{$ngram} times\n";
      $count++; 
    }
  }
  if ($totalWords == 0) {
    $totalWords = $count;
  }
}
#-------------------------------------------------------------------------
# Breaks a text file down into n-grams - Used for 2nd ngram > 2
#-------------------------------------------------------------------------
sub ngram {
  my (@w) =@_;
  my $thisKey;
  my $count = 0;

  foreach my $i (0 .. $#strings){
    # Split each sentence by white-space, removing it
    my @w = split /\s+/, $strings[$i];
    my $size = $n-2;
    foreach my $k (0 .. $#w-$size)
    {
      my $ngram = $w[$k] . " ";
      for (my $i=1; $i<=$size; $i++) 
      {
        if ($i != $size) {
          $ngram .= $w[$k+$i] . " ";
        } else {
          $ngram .= $w[$k+$i] . " ";  
        }
      }  
      $wordCount{$ngram}++;
#      print ">>>> $n-gram: \"$ngram\" occurs $wordCount{$ngram} times\n";
      $count++; 
    }
  }
  if ($totalWords == 0) {
    $totalWords = $count;
  } 
}

#---------------------------------------------------
# Calculate the probability table
#---------------------------------------------------

sub probability {
  my () = @_;
  my %generator;
  my $totalProb = 0;
    
#   For every word in the n-1gram, find a match from the ngram
    foreach my $key (sort { $library{$b} <=> $library{$a} } keys %library) {

#     Split the key to be able to find the first word of the string
      my @p = split / /, $key;
#      print "@p\n";
      
      # Depending on n, look for a string with multiple words
      my $found = "";
      for (my $i = 1; $i < $n; $i++) {
        $found .= $p[$i] . " ";
      }
      chop $found;
#      print "Looking for: $found in $wordCount{$found}\n\n";
      if (exists $wordCount{$found}) {
      
#        print "Found \"$found\" from \"$key\"\n";
#        print "\"$found\" occurs $wordCount{$found} times in wordCount\n";
#        print "\"$key\" occurs $library{$key} times in library\n";
#        print "Probability = $wordCount{$found} / $totalWords * $library{$key} / $wordCount{$found}\n"; 
        my $prob = $wordCount{$found}/$totalWords*$library{$key}/$wordCount{$found};
#        print "$key:\t $prob\t Total: $totalProb\n"; 
        $generator{$totalProb} = $key;
        $totalProb += $prob;
      } 
    }
#    Probability = unigram/total * bigram/unigram
#    print "Total Probability = $totalProb\n\n";
#      print "$_\n" for keys %wordCount;
#      print "\n";
#      print "$_\n" for keys %library;

  return %generator;
}

#------------------------------------------------------------------------
# Sentence generator will take create m number of sentences based on the 
# probability of word occurrence. 
#------------------------------------------------------------------------

sub senGen {
  my ($m) = @_;
  my %generator;
  my $totalProb = 0;
  my $addWord;
  my $sen = "";
  my $run = 0;

# Determine the frequency of each word and sort (sum of all frequencies is 1)
#  print ">>> The value of n is $n\n";
  if ($n == 1) {
    my @words = sort {$wordCount{$b} <=> $wordCount{$a}} keys %wordCount;
    for my $word (@words) {
      my $prob = $wordCount{$word}/$totalWords;

#      print "$word: $wordCount{$word} / $totalWords = $prob. Total: $totalProb\n"; 

#      print "$word:\t $prob\t Total: $totalProb\n"; 
      $generator{$totalProb} = $word;
      $totalProb += $prob;
#      print "Total Probability = $totalProb\n\n";

    }
  } 
  else {
#    my @words = sort {$wordCount{$b} <=> $wordCount{$a}} keys %wordCount;
#    my @words2 = sort {$library{$b} <=> $library{$a}} keys %library;
    %generator = probability();         #@words, @words2);
#    print "GENERATOR: $_\n" for keys %generator;

  }
#---------------------------------------------------------------------------
# Generate a random number between 0-1 which correlates with the probability 
# of a word occurring.  Use that word, then move on to the next until a
# punctuation character is displayed.  That will indicate the end of the 
# sentence.  The number of sentences produced will be based on user input $m
#---------------------------------------------------------------------------
#=cut
  my @wds = sort keys %generator;
  my $s = 1;
  while ($s <= $m) {
    while ($run == 0) {
      my $random = rand();
      #print "Random Number: $random\n";
      for my $w (@wds) {
        if ($w <= $random){        #($w < $random){
          #print "$w: $generator{$w}\n";
          $addWord = $generator{$w};
        }
      }
#      print "Addword: $addWord \n";
      if ($addWord =~/[.?!]/){
        if ($sen ne "") {
          chop($sen);
          #my $lastChar = substr($sen,length($sen)-1);
          #print "LAST CHARACTER (!?.): $lastChar\n";
            $sen .= $addWord;
            $run = 1;
        } 
      } 
      elsif ($addWord =~/(<start>|<end>|,|"|\(|\)|')/){
          # Remove all strings of this type
          $addWord =~s/<end>//g;
#          print "Addword (modified): $addWord ~ $' ~ $& \n";
          if (($'=~/\s*(<start>| <end>|,|"|\(|\)|')\s*/) && ($'=~/\s*(<start>| <end>|,|"|\(|\)|')\s*/)){  
            $sen = $sen;
          
          }
          elsif ($'=~/\s*(<start>| <end>|,|"|\(|\)|')\s*/){
#            print "1\n";
            $sen .= $& . " ";
          }
          else {
#            print "2\n";
            $sen .= $' . " ";
          }

      } 
      elsif ($addWord eq "i"){
        $sen .= "I" . " ";
      } 
        else {
          $sen .= $addWord . " ";
        }
      }

      #print "Before Space repalce: $sen\n";
      $sen =~ s/\s+/ /g;
      $sen =~ s/ \././g;
      $sen =~ s/<end>//g;
      $sen =~ s/^ //g;
      $sen = ucfirst($sen);
      print "Sentence $s: $sen\n\n";
      $run = 0;
      $sen = "";
      $s++;
#      foreach my $f (keys %library) {
#        foreach my $g (keys %{$library{$f}} ) {
#          print "$f/$g occurs ($library{$f}{$g} times.\n";
#        }  
#      }
    }
=cut
      elsif ($n == 2) {
        my @prob1 = gramProbability($n);
        my $x = @prob1;
        for (my $i = 0; $i < $x; $i++){

          print "$prob1[$i][0] $prob1[$i][1] $prob1[$i][2]\n";
        }
      }
    else {
      my @prob1 = gramProbability(%library);
      my $x = @prob1;
      for (my $i = 0; $i < $x; $i++){

#print "Prob1: $prob1[$i][0] $prob1[$i][1] $prob1[$i][2]\n";
      }
      my @prob2 = gramProbability(%library);
      $x = @prob2;
      for (my $i = 0; $i < $x; $i++){

#print "Prob2: $prob2[$i][0] $prob2[$i][1] $prob2[$i][2]\n\n";
      }

    }
=cut
}

#---------------------------------------------------------------
# Creates an multidimensional array which includes the word, the following words,
# and the number of time phrase follows the initial word.  This array is sorted 
# by the number of occurrences of these ngram pairs.
#---------------------------------------------------------------


sub gramProbability {
  my (%library) = @_;
  my %lib = %library;
  my $x = 0;
  foreach my $f (keys %lib) {
    foreach my $g (keys %{$lib{$f}} ) {

#      print "\"$f\" occurs before \"$g\" $library{$f}{$g} times.\n";
      $gramValue[$x][0] = $f;
      $gramValue[$x][1] = $g;
      $gramValue[$x][2] = $lib{$f}{$g};
      $x++;

    }  
  }
  my @gramValue = sort { $a->[0] cmp $b->[0] } @gramValue;
  return @gramValue;
}

#-------------------------------------------------------------
# Takes in an input text file, strips off the end-line characters, turns 
# everything lowercase, and puts it all in a single string.
#
# Some of parseFile() code snippet from: 
# https://perlmaven.com/open-and-read-from-files
#--------------------------------------------------------------
sub parseFile {
  my ($file) = @_;
  
  if (open(my $text, '<:encoding(UTF-8)', $file)){
    while (my $str = <$text>) {
      
      chomp $str;
      $str = lc($str);
      $bookStr .= $str . " ";
    } 
  } else {
    warn "Could not open file '$file'.\n$!";
  }
  return $bookStr;
}

#------------------------------------------------------
# makeGramable takes the string passed in from the text file and makes it ready
# to be analyzed by a specific n-gram model.  Punctuation is removed and where 
# appropriate is replaced with start and end tags.  Depending on what n-gram
# model is required, there will be additional start tags added in order to verify
# the beginning of a sentence. Each sentence is a separate element in the array.
#------------------------------------------------------
sub makeGramable{
  my($str, $n) = @_;
  my $len = length $str;
  my $nStart = "<start> ";
 
  # Depending on n-gram model, additional start tags will be required.
  if ($n > 1) {
    for (my $gram = 1; $gram < $n; $gram++){
      $nStart .= "<start> ";
    }
  }
  
  #-----------------------------------------------
  # In order to get rid of wide character warning that was coming up when taking
  # in the character " , I used this code snippet from
  # http://www.perlmonks.org/?node_id=613765
  #       /ge is for global exchange
  #-----------------------------------------------
  $str =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
  
  # Space punctuation to be added to ngram model
  
  if ($str =~ / '[a-z]+'/){
    print "STRING TO BE FIXED: $str\n";
    print "regex: $&\n";
    print "target before: $`\n";
    print "target after: $'\n";
    my $part = substr($&, 2);
    chop $part;
    print "Substring: $part\n\n";
    $str = $` . " ' $part '" . $';
  }
  $str =~ s/^'/ ' /g;           # Keeping contractions as a single word.
  $str =~ s/\"/ \" /g;
  $str =~ s/,/ , /g;
  $str =~ s/\(/ \( /g;
  $str =~ s/\)/ \) /g;
  $str =~ s/\./ \. /g;
  $str =~ s/\!/ \! /g;
  $str =~ s/\?/ \? /g;

  # Split sentences based on punctuation
  my @strings = split (/(?<=\.)\s*|(?<=\?)\s*|(?<=\!)\s*/, $str);
  #my @strings = split /\.\s+|\?\s+|\!\s+/, $str;

  foreach my $i (0 .. $#strings){
    $strings[$i] = $nStart . $strings[$i] . " <end>";
#    ngram($strings[$i]);
#    print "String $i: $strings[$i]\n";

  }

  return @strings;
}






