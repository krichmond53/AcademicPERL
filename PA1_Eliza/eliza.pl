#!/usr/bin/perl -w
use Switch;           # Switch cases made things a lot easier

#---------------------------------------------
# Kevin Richmond
# CMSC 416 - Natural Language Processing
# Programming Project 1 - Eliza
#
# Eliza is a interactive psychotherapists who is meant to treat clients by
# listening to their problems and helping them get to the root cause
# 
# This program is run from the command line then the user will interact via
# keyboard until they are finished.  To exit, the user must type in "bye".
#
# Eliza uses an infinite loop which continuously analyzes the user input.  First
# it looks for keywords or key phrases that a client might type.  Once found, the
# client's statement is transposed so that personal pronouns are switched from
# 1st to 3rd person or vice-versa.  There have been 3-5 responses given for 
# each key.  These are randomly determined # by taking mod (%) of a counter which
# increments with each loop.  These responses are given back to the client to 
# encourage further conversation.
#---------------------------------------------

#---------------------------------------------------
# Defining variables to be used in Eliza's session
#---------------------------------------------------
$doc = "eliza";
$prog = 1;            # State of the program - 1 or 0
$count = 10;          # Counter to make selecting responses 'random'

#----------------------------------------------------------
#  Introduction will always be the same - Hard coded
#----------------------------------------------------------
print "-> [$doc] Hi, I'm a psychotherapist. What is your name?\n";
print "=> [] ";
my $client = <STDIN>;
chomp $client;
print "-> [$doc] Hi $client. How are you feeling today?\n";

#---------------------------------------------------
# Begin running psychotherapist loop
#--------------------------------------------------
while ($prog == 1) {
  print "=> [$client] ";
  my $input = lc(<STDIN>);
  $userIn = $input;
  $count++;

  # Check for keywords or terms
  findKey($userIn);
  
}

#-----------------------------------------------
# This function will find the key word or phrase of the client and use that
# to provide a response relative to their input.
#-----------------------------------------------
sub findKey {
  my ($str) = @_;
  chomp $str;

  if ($str =~/\bi need \b/){
    my $rem = $';
    needRes($rem);

  # When the user hits enter or just leaves white space as a response
  } elsif ($userIn =~/^\s*$/) {
    print "-> [$doc] You must have something on your mind. What is it?\n";
  
  # To exit conversation with Eliza  
  } elsif ($userIn =~/\bbye|exit|quit\b/) {
    endEliza();
  
  } elsif ($str =~/\bi can[ ]*not \b/){
    my $rem = $';
    cantRes($rem);

  } elsif ($str =~/\bwhat \b/){
    my $rem = $';
    whatRes($rem);
  
  } elsif ($str =~/\bhow \b/){
    my $rem = $';
    howRes($rem);

  } elsif ($str =~/\bhi|hello|howdy\b/){
    my $rem = $&;
    greetingRes($rem);

  } elsif ($str =~/\bi want \b/){
    my $rem = $';
    wantRes($rem);
  
  } elsif ($str =~/^([A-Za-z]+\s)*\b(mother|mom|mommy)\b([\sA-Za-z]+)*/){
    my $rem = $';
    momRes($rem);

  } elsif ($str =~/^([A-Za-z]+\s)*\b(father|dad|daddy)\b([\sA-Za-z]+)*/){
    my $rem = $';
    dadRes($rem);

  } elsif ($str =~/^([A-Za-z]+\s)*\b(desire|crave|love)\b([\sA-Za-z]+)*/){
    my $rem = $&;
    desireRes($rem);

  } elsif ($str =~/^([A-Za-z]+\s)*\b(sad|lonely|depressed)\b([\sA-Za-z]+)*/){
    my $rem = $&;
    sadRes($rem);

  } elsif ($str =~/^([A-Za-z]+\s)*\b(silly|funny|amusing)\b(\sA-Za-z]+)*/){
    my $rem = $&;
    sillyRes($rem);

  } elsif ($str =~/\bbecause\b/){
    my $rem = $';
    becauseRes($rem);

  } elsif ($str =~/\bwhy \b/){
    my $rem = $';
    whyRes($rem);
  
  } else {
    otherRes($str);
  }
}

#-------------------------------------------------------------------
# The following several functions are responses to the specific key words and 
# phrases in the function above.  They are randomized based on mod of the counter
# which iterates every time the program goes through its main loop.
#-------------------------------------------------------------------
sub whyRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] Why do you think?\n"}
    case 1 {print "->[$doc] Y is a crooked letter.  It's a joke.  Laugh!  Why... Y.... Hahahahaha!\n"}
    case 2 {print "->[$doc] I'm not completely sure what that has to do with our session.\n"}
  }
}

sub becauseRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);
  my $capStr = ucfirst(substr($str,1));

  switch ($val) {
    case 0 {print "->[$doc] Is that really the case?\n"}
    case 1 {print "->[$doc] $capStr?\n"}
    case 2 {print "->[$doc] Do any other reasons pop into your head?\n"}
  }
}

sub sillyRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);
  my $capStr = ucfirst($str);

  switch ($val) {
    case 0 {print "->[$doc] $capStr can be good or bad.  What is so $str?\n"}
    case 1 {print "->[$doc] They say that laughter is light a good medicine.\n"}
    case 2 {print "->[$doc] If it's $str, that's probably not a bad thing.  What do your friends think?\n"}
  }
}

sub sadRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);
  my $capStr = ucfirst($str);

  switch ($val) {
    case 0 {print "->[$doc] I'm sorry to hear that. What is making you $str?\n"}
    case 1 {print "->[$doc] How unpleasant! Can you tell me more about what's casing you to be $str?\n"}
    case 2 {print "->[$doc] $capStr? Sorry to hear that. What do you think would make you not so $str?\n"}
  }
}

sub desireRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);
  $ingStr = substr($str, 0, (length $str)-1) . "ing"; 

  switch ($val) {
    case 0 {print "->[$doc] Do you believe this $ingStr is helpful?\n"}
    case 1 {print "->[$doc] Please tell me a bit more about your $ingStr.\n"}
    case 2 {print "->[$doc] Do you think this $str will be the same in a year's time?\n"}
  }
}

sub dadRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] How does your father make you feel today?\n"}
    case 1 {print "->[$doc] What kind of father was he?\n"}
    case 2 {print "->[$doc] Help me understand a little more about him. How did he treat you?\n"}
  }
}

sub momRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] Interesting.  Can you tell me more about your mom?\n"}
    case 1 {print "->[$doc] What was your relationship with her like?\n"}
    case 2 {print "->[$doc] How does this impact on your life today?.\n"}
  }
}

sub wantRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] What makes you want $str\n"}
    case 1 {print "->[$doc] If you were to receive $str, what would you do?\n"}
    case 2 {print "->[$doc] What would change if you got $str?\n"}
  }
}

sub greetingRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %5);
  my $capStr = ucfirst($str);

  switch ($val) {
    case 0 {print "->[$doc] It's great to see you today!\n"}
    case 1 {print "->[$doc] How is the weather outside?  I have been in this office all day!\n"}
    case 2 {print "->[$doc] Glad you could make it. What can I help you with?\n"}
    case 3 {print "->[$doc] You're looking awfully nice. Did you do something to your hair?\n"}
    case 4 {print "->[$doc] $capStr, $str, $str!\n"}
  }
}

sub otherRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %6);
  my $capStr = ucfirst($str);
  
  switch ($val) {
    case 0 {print "->[$doc] $capStr?\n"}
    case 1 {print "->[$doc] Can you go into more depth with that?\n"}
    case 2 {print "->[$doc] Quite interesting.\n"}
    case 3 {print "->[$doc] How does that make you feel?\n"}
    case 4 {print "->[$doc] Why do you say $str?\n"}
    case 5 {print "->[$doc] I think I understand.  Could you elaborate a bit more?\n"}
  }
}

sub howRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] How do you think?\n"}
    case 1 {print "->[$doc] Is that something that I really need to answer??\n"}
    case 2 {print "->[$doc] What's the real reason for asking this?\n"}
  }
}

sub whatRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] What are your thoughs?\n"}
    case 1 {print "->[$doc] Have you been wondering this long?\n"}
    case 2 {print "->[$doc] Why do you think an answer to that could that help you?\n"}
  }
}

sub cantRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] Why is it so hard to $str?\n"}
    case 1 {print "->[$doc] When was the last time you tried to $str?\n"}
    case 2 {print "->[$doc] What keeps you from $str?\n"}
  }
}

sub needRes {
  my ($feels) = @_;
  chomp $feels;
  $str = transpose($feels);
  my $val = ($count %3);

  switch ($val) {
    case 0 {print "->[$doc] Why do you need $str?\n"}
    case 1 {print "->[$doc] What makes you think you need $str?\n"}
    case 2 {print "->[$doc] Are you sure you need $str?\n"}
  }
}

#---------------------------------------------------------------------------
# When responding to the user, the therapist's answers must be in the proper 
# pronoun form.  This transpose function will take words from 3rd person and
# change them to 1st person and vice versa.  Part of this function will also 
# remove 1 period character, in that it is expected that the user will make single
# statements.
#--------------------------------------------------------------------------
sub transpose {
  my ($input) = @_;
  my $newStr = "";

  # Split apart all the words in the string
  @part = split / /, $input;
  $len = @part;                 # Number of words in array
 
  # Check for 1s or 3rd person pronouns and transpose them 
  for (my $i=0; $i<$len; $i++){
    
    # Remove punctuation (. only at this time)
    my $wordLen = length $part[$i];
    my $last = substr($part[$i], $wordLen-1, 1);
    if ($last eq '.') {
      chop $part[$i];
    }
    
    if ($part[$i] =~/\byour\b/){
      $part[$i]=~s/\byour\b/my/;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\byou\b/){
      $part[$i]=~s/\byou\b/me/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\byourself\b/){
      $part[$i]=~s/\byourself\b/myself/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\byours\b/){
      $part[$i]=~s/\byours\b/mine/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\bmy\b/){
      $part[$i]=~s/\bmy\b/your/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\bi\b/){
      $part[$i]=~s/\bi\b/you/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\bme\b/){
      $part[$i]=~s/\bme\b/you/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\bmyself\b/){
      $part[$i]=~s/\bmyself\b/yourself/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\bmine\b/){
      $part[$i]=~s/\bmine\b/yours/g;
      $newStr .= $part[$i] . " ";

    } elsif ($part[$i] =~/\bam\b/){
      $part[$i]=~s/\bam\b/are/g;
      $newStr .= $part[$i] . " ";

    } else {
      $newStr .= $part[$i] . " ";
    }
  }
  
  chop $newStr;
  return $newStr;
}

#----------------------------------------------------------
# This is the function which will quit the Eliza session
#----------------------------------------------------------
sub endEliza {
  print "-> [$doc] If you really wish to end our session, just type \"yes\".\n";
  print "=> [$client] ";
  my $exit = lc(<STDIN>);
  if ($exit =~/^y/)  {
    print "-> [$doc] I hope you have found some comfort in our time together.\n";
    $prog = 0;
  } else {
    print "-> [$doc] Ok then.  Let's get back to our session.\n";
  }
}


