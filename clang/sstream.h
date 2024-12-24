#ifndef SSTREAM_H_
#define SSTREAM_H_

#include <stdbool.h>
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

#endif // SSTREAM_H_

#ifdef SSTREAM_IMPLEMENTATION

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

bool Ss_init(Sstream *ss) {
  if (ss == NULL) {
    fprintf(stderr, "ERROR: Parameter `ss` can not be null, %s:%d\n", __FILE__,
            __LINE__);
    return false;
  }
  ss->data = NULL;
  ss->max_size = 0;
  ss->current_size = 0;
  ss->init = true;
  return true;
}

bool Ss_add(Sstream *ss, char *str) {
  if (ss == NULL || str == NULL) {
    fprintf(stderr, "ERROR: Parameters can not be null, %s:%d\n", __FILE__,
            __LINE__);
    return false;
  }

  if (!ss->init) {
    fprintf(stderr, "ERROR: Sstream has not been initialized, %s:%d\n",
            __FILE__, __LINE__);
    return false;
  }
  size_t size = strlen(str);
  size_t new_size = ss->current_size + size;

  if (new_size >= ss->max_size) {
    ss->max_size = new_size * 2;
    ss->data = (char *)realloc(ss->data, ss->max_size);
    if (ss->data == NULL) {
      fprintf(stderr, "ERROR: Memory allocation failed, %s:%d\n", __FILE__,
              __LINE__);
      return false;
    }
  }

  memcpy(ss->data + ss->current_size, str, new_size - ss->current_size);
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
    fprintf(stderr, "ERROR: Sstream can not be NULL, %s:%d\n", __FILE__,
            __LINE__);
    return NULL;
  }
  if (ss->data == NULL) {
    fprintf(stderr, "ERROR: Sstream data can not be NULL, %s:%d\n", __FILE__,
            __LINE__);
    return NULL;
  }

  char *str = (char *)malloc(ss->current_size + 1);
  if (str == NULL) {
    fprintf(stderr, "ERROR: Memory allocation failed, %s:%d\n", __FILE__,
            __LINE__);
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
#endif // SSTREAM_IMPLEMENTATION
