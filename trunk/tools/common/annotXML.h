#ifndef ANNOTXMLH
#define ANNOTXMLH

#include "annotContainer.h"
#include <iostream>
#include <fstream>

typedef infoNode* document;

class parserXML
{
  private:
  ifstream file;
  char current;
  void read_next();
  bool is_blank(char c);
  int parse_blank();
  string parse_text_until(char c);
  void parse_tag(infoNode* n);

  public:
  document load_from_file(const string &filename);
};

class writerXML
{
  ofstream file;
  void write_node(int ntab, infoNode* node);

  public:
  void save_to_file(document doc, const string &filename);
};


#endif
