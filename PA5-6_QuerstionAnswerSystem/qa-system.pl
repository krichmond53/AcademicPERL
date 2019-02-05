#!/usr/bin/perl -w
use strict;
use warnings;
use Text::Unidecode;
use Lingua::StopWords qw(getStopWords);
use WWW::Wikipedia;

#---------------------------------------------
# Kevin Richmond - March 2018
# CMSC 416 - Natural Language Processing
# Programming Project 6 - ENHANCED Question/Answer System
# 
# Problem: 
#   When a question is posed, the computer should be able to automatically answer
#   it by looking through the internet to find the answer.  In this case, we are
#   using Wikipedia as our internet database.
#
# Example input (identified by Q? ==>) and output (identified by A. ==>):
#   Q? ==>  Who is Bob Dylan?
#
#   A. ==>  Bob Dylan is an American singer-songwriter, author, and painter who has been an influential figure in popular music and culture for more than five decades.
#   Q? ==>  Who is Ralph Stanley?
#   A. ==>  Ralph Stanley was an American bluegrass artist, known for his distinctive singing and banjo playing.
#   Q? ==>  Who is Jet Li?
#   A. ==>  Jet Li is a Chinese film actor, film producer, martial artist, and retired Wushu champion who was born in Beijing.
#   Q? ==>  Who is George Washington?
#   A. ==>  George Washington was an American statesman and soldier who served as the first President of the United States from 1789 to 1797 and was one of the Founding Fathers of the United States.
#   Q? ==>  Who is RZA?
#   A. ==>  RZA, is an American rapper, record producer, musician, actor, filmmaker and author.
#        
# Description of Algorithm:
#   The QA System first takes the user's input question and parses it to remove
#   any stop words up until the first non-stopword.  This is to allow for phrases
#   to be asked that may include stopwords.  After the key words were taken out,
#   each query was reformed into a set of the key words and other possible phrases
#   that would match whichever type of question was being asked.  Who and What 
#   questions had similar matching phrases where When and Where were a lot more
#   complex and required additional matching phrases.
#   
#   After the keywords and matching phrases were put together, the program would
#   search Wikipedia for the key word, such as "George Washington" if the question
#   was "Who was George Washington?".  The cpan Wikipedia module was set to return
#   the full text of the article, where some of that text was unreadable by humans.
#   At this point, the article was parsed based on "." assuming that all text 
#   before that would constitute a sentence.  This allowed for each sentence to 
#   be represented as an element in an array and searched for the phrase to be 
#   matched.
#
#   When a match was found, it would be stored in an array and passed into another
#   subroutine which would determine which of the answers was appropriate.  As a   
#   starting point, it has been assumed that the first entry would always be the 
#   best representation of an answer to the question being asked by the user. In
#   some cases, this was not true.  Sometimes the first answer returned gibberish.
#   Sometimes the answer returned had extraneous information which had to be 
#   parsed out.
#
#   Once the answer was cleaned up and determined to be correct, the program
#   would output an answer.  If the program did not come up with a suitable 
#   answer, it would respond that it did not have the answer to the question.
#
#
#
# *****************************************************************************
# Enhancements:
#  1) Query Reformation
#   Instead of individually performing query reformations based on the initial
#   user input, the query is now a hash based on all the words given by the user.
#   This hash then has other terms added to it based on what type of question
#   the user is asking.  The words of this hash is then compared with each 
#   sentence from the Wiki article.
#  2) Answer Composition
#   Incomplete
#  3) Confidence Score
#   When each possible candidate for a good answer is found, the number of key
#   words per sentence are added and then a grand total is taken.  The confidence
#   score is the number of matches found in the sentence divide by the total 
#   number of key word matches throughout the possible candidates.  This leaves
#   most confidence numbers to be fairly low and the results do not seem to be
#   as accurate as the previous version.
# *****************************************************************************
#
#
#
##---------------------------------------------------------------------------

my $program = $0;
my $logfile = $ARGV[0];
my $stopwords = getStopWords('en');
#print "\nCOMMAND LINE INPUT: $program $logfile\n\n";

#--------------------------------------------------------------------------
# Opens a log file for debugging purpose
#--------------------------------------------------------------------------
open(my $fh, '>', $logfile);

# Upon starting, print name and description of what the program does
print "This is a QA system by Kevin Richmond. It attempts to answer your questions whichs starts with Who, What, When or Where. \"EXIT\" will end the program.\n";

# Prompt user for question until "exit" is entered
my @reformedQueries = userAsksQuestions();
my %userWords;       #  User's query and words associated with questions 
my %possible;     #  Sentences from Wiki which could be possible answers

#--------------------------------------------------------------------------
# Main while loop that continues to allow user to ask questions until EXIT.
#--------------------------------------------------------------------------
sub userAsksQuestions {
#  my () = @_;
  my $userIn = ""; 
  my @reformedQueries;
  my $keyWords;
    

  while ($userIn ne "EXIT") {
    print "\nQ? ==>  ";
    $userIn = <STDIN>;
    chomp $userIn;
    print $fh ">>>>>>>>>>>>>>>  User's Question: $userIn\n";
    my $article;
    my $type;
    my $total;
    my $confidence;
    my $bestAnswer;
    my $bestValue = 0;
    %userWords= ();
    %possible = ();

    if (lc(substr $userIn, 0, 4) eq "exit") {
      close $fh;
      last;

    } else {
      # Parse entire user input and put in hash, unless EXIT
      %userWords = getWords($userIn);
      
      # Check hash to see if who, what, when, where then add associated terms
      $type = getType(\%userWords);
      
      # Get searchable term from user input
      $keyWords = getKeyWords($userIn, $type);
#      print "Search for $keyWords.\n";

      # Retrieve article text from Wikipedia
      $article = searchWiki($keyWords);

      # Parse article into sentence, looking for associated terms
      if (length $article) {
        $total = match($article);


      } else {
        print "\nA. ==>  I do not have the answer to that question.\n";
        print $fh "Response:  I don't know what you mean.  Please ask again.\n";
      }

      # Determine which sentence fits best by confidence score
      # Compose concise answers
      # Delete everything in hash after each question

      print "Question type: $type\nSearching for $keyWords:\n";
      foreach my $t (keys %possible) {
#        print "$t\n Key word matches: $possible{$t}\n\n";
        if ($possible{$t} > $bestValue) {
          $bestValue = $possible{$t};
          $bestAnswer = $t;
        }
      }

      if ($total) {
        $confidence = $bestValue/$total;
      }
      print "Best sentence is:\n$bestAnswer\n\nConfidence: $confidence\n";
    }

#      print $fh "Response:  I don't know what you mean.  Please ask again.\n";
#      print "A. ==>  I don't know what you mean.  Please ask again.\n";

    }
  #print $article;

}

#--------------------------------------------------------------------------
# Take the phrases from Wikipedia which matched the reformed queries
#--------------------------------------------------------------------------
sub makeAnswer{ 
  my ($fnd, $key, $type) = @_;
  my @f = @{$_[0]};
  my @answer;
  my $i = 0;

  foreach (@f) {
    my $temp = $_;
    $temp = tr/"\n"/" "/;  
#    print "\nFound: $_\n";
    
    # Assuming the first sentence returned accurately represents the answer
    if ($_ =~/\Q$key/) {
      print $fh "\nPOSSIBLE ANSWER: ($key) $& $'\n";
      
      if ($' =~ /^[',"]*/) {
        $temp = substr $', 0;
        $answer[$i] = $key . $temp . ".";
      } else {
        $answer[$i] = $key . $' . ".";
      }
    }
    $i++;
  }
  
  foreach (@answer) {
    print $fh "\nANSWER: $_\n";
  }


  if (length $answer[0]) { 
    if ($answer[0] =~ / \(.*?\)/) {
      $answer[0] = $` . $'
    }
    if ($type eq "what") {
      $answer[0] = "A " . $answer[0];
    } elsif ($type eq "when") {
      $answer[0] = "The " . $answer[0];
    }
    $answer[0] =~ s/<ref>//;
    $answer[0] =~ s/<\/ref>//;
    $answer[0] = ucfirst($answer[0]);
#    print "\n>>> FINAL ANSWER: $answer[0]\n";
  }
  return $answer[0];
}

#--------------------------------------------------------------------------
# Match key words and reformed queries against the Wikipedia Article
#--------------------------------------------------------------------------
sub match{
  my ($article) = @_;
  
  # Split articles into array of sentences
  my @sen = split /\./, $article;
  my $senLen = @sen;
  my $number;
  my $ct;
  my $total;

  # Look at each sentence, searching for matching associated terms
  # Use all lowercase in order to prevent overlooking something
  foreach my $s (@sen) {
    $ct = 0;
    $s =~ s/\n//; 
#    print "\nIn the sentence:\n$s\n";

    foreach my $key (keys %userWords) {
      $number = () = $s =~ /\b$key\b/gi;
      if ($number > 0) {   
#        print "Found $key, total of $number times.\n";
        $userWords{$key} = $number;
        $ct += $number;
      }
    }
#    print "Sentence Total: $ct\n";
    if ($ct > 0) {
      $possible{$s} = $ct;
    }

    $total += $ct;
    
  }

#  print "Grand Total: $total\n\n";
  return $total;
}




#--------------------------------------------------------------------------
# Get the key words of the user's question
#--------------------------------------------------------------------------
sub getKeyWords{
  my ($str,$t) = @_;

  if ($t eq "who") {
    $str = substr $str, 4;
  } elsif (($t eq "when") || ($t eq "what")) {
    $str = substr $str, 5;
  } elsif ($t eq "where") {
    $str = substr $str, 6;
  }
  chop $str;

  my @words = split(/ /, $str);
  my %hash = %{$stopwords};
  my $part = 0;
  my $s;

  foreach (@words) {
    if ((exists $hash{$_}) && ($part == 0)) {
#      print "STOPWORD: $_\n";
    } else {
#      print "NON-STOPWORD: $_\n";
      $s .= $_ . " ";
      $part = 1;
    }
  }

#  print "Keywords: $s\n";
#  @mainWords[0] = $s;
  chop $s;
  return $s;                #@mainWords;
}

#--------------------------------------------------------------------------
# Search Wikipedia for keyword and return the article
#--------------------------------------------------------------------------
sub searchWiki{ 
  my (@query) = @_;

#  print "Searching Wiki for $query[0]\n";
  my $wiki = WWW::Wikipedia->new();
  my $entry = $wiki->search( $query[0] );
  if (length $entry) {
#    $entry = $entry->fulltext();
#    $entry = $entry->title();
    $entry = $entry->text();
  }

#  print "$entry";
  $entry =~ s/[^[:ascii:]]+//g;  # Deals with wide-character error.  
  return $entry;
}

#-------------------------------------------------------------------
# Puts all words from user's question in a hash
#-------------------------------------------------------------------
sub getWords {
  my ($w) = @_;
  my @words = split / /, $w;
  my %hash;

  foreach my $w (@words){
    $w =~ s/\?//;
    $hash{$w}++;    
  }
  
  return %hash;
}

#-------------------------------------------------------------------
# Check to see which type of question is being asked and add associated terms
#-------------------------------------------------------------------
sub getType {
  my $words = shift;
  my %hash = %$words;
  my $type = "";

  if (exists $hash{"Who"}) {
    $type = "who";
    delete $userWords{"Who"};
    $userWords{"is"}++;
    $userWords{"was"}++;
    $userWords{"a"}++;
    $userWords{"an"}++;

  } elsif (exists $hash{"What"}) {
    $type = "what";
    delete $userWords{"What"};
    $userWords{"is"}++;
    $userWords{"was"}++;
    $userWords{"a"}++;
    $userWords{"an"}++;
    $userWords{"any"}++;

  } elsif (exists $hash{"Where"}) {
    $type = "where";
    delete $userWords{"Where"};
    $userWords{"occurred"}++;
    $userWords{"occur"}++;
    $userWords{"lasted"}++;
    $userWords{"from"}++;
    $userWords{"took"}++;
    $userWords{"place"}++;
    $userWords{"on"}++;
    $userWords{"in"}++;
    $userWords{"period"}++;
    $userWords{"January"}++;
    $userWords{"February"}++;
    $userWords{"March"}++;
    $userWords{"April"}++;
    $userWords{"May"}++;
    $userWords{"June"}++;
    $userWords{"July"}++;
    $userWords{"August"}++;
    $userWords{"September"}++;
    $userWords{"October"}++;
    $userWords{"November"}++;
    $userWords{"December"}++;

  } elsif (exists $hash{"When"}) {
    $type = "when";
    delete $userWords{"When"};
    $userWords{"region"}++;
    $userWords{"located"}++;
    $userWords{"just"}++;
    $userWords{"is"}++;
    $userWords{"a"}++;
    $userWords{"an"}++;

  } else {
    print "A. ==> I do not know what you mean.  Please ask again.\n";
  }

  return $type;
}


