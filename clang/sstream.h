#ifndef SSTREAM_H
#define SSTREAM_H
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  char *data;
  size_t max_size;
  size_t current_size;
  bool init;
} Sstream;

bool Ss_init(Sstream *ss);
bool Ss_add(Sstream *ss, char *str);
bool Ss_addmany(Sstream *ss, char *strings[], size_t num_strings);
bool Ss_addlist(Sstream *ss, char *strings[], size_t num_strings, char *sep);
char *Ss_tostring(Sstream *ss);

#endif

#ifdef SSTREAM_IMPLEMENTATION

bool Ss_init(Sstream *ss) {
  ss->data = NULL;
  ss->max_size = 0;
  ss->current_size = 0;
  ss->init = true;
  return true;
}

bool Ss_add(Sstream *ss, char *str) {
  if (ss == NULL || str == NULL) {
    fprintf(stderr, "ERROR: Parameters can not be null\n");
    return false;
  }

  if (!ss->init) {
    fprintf(stderr, "ERROR: Sstream has not been initialized\n");
    return false;
  }
  size_t size = strlen(str);
  size_t new_size = ss->current_size + size;

  if (new_size >= ss->max_size) {
    ss->max_size = new_size * 2;
    ss->data = (char *)realloc(ss->data, ss->max_size);
    if (ss->data == NULL) {
      fprintf(stderr, "ERROR: Memory allocation failed\n");
      return false;
    }
  }

  size_t offset = ss->current_size;
  for (int i = 0; i < size; i++) {
    size_t actual_size = i + offset;
    ss->data[actual_size] = str[i];
  }
  ss->current_size = new_size;
  return true;
}

bool Ss_addmany(Sstream *ss, char *strings[], size_t num_strings) {
  for (int i = 0; i < num_strings; i++) {
    if (!Ss_add(ss, strings[i])) {
      return false;
    };
  }
  return true;
}

bool Ss_addlist(Sstream *ss, char *strings[], size_t num_strings, char *sep) {
  for (int i = 0; i < num_strings; i++) {
    if (!Ss_add(ss, strings[i])) {
      return false;
    };
    if (i != num_strings - 1) {
      if (!Ss_add(ss, sep)) {
        return false;
      };
    }
  }
  return true;
}

char *Ss_tostring(Sstream *ss) {
  if (ss == NULL) {
    fprintf(stderr, "ERROR: Sstream can not be NULL\n");
    return NULL;
  }
  if (ss->data == NULL) {
    fprintf(stderr, "ERROR: Sstream data can not be NULL\n");
    return NULL;
  }

  char *str = malloc(ss->current_size + 1);
  if (str == NULL) {
    fprintf(stderr, "ERROR: Memory allocation failed\n");
    return NULL;
  }

  memcpy(str, ss->data, ss->current_size);
  str[ss->current_size] = '\0';

  free(ss->data);
  ss->data = NULL;
  ss->current_size = 0;
  ss->max_size = 0;

  return str;
}
#endif
