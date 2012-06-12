CC := clang
CFLAGS := -std=c99 -Werror -Weverything

CXX := clang++
CXXNOWARN := global-constructors variadic-macros
CXXFLAGS := -std=c++98 -Weverything $(CXXNOWARN:%=-Wno-%)

RM := rm -f
PERL := perl
ECHO := echo

SPECS := $(wildcard spec/*)
GEN_FILES := $(patsubst gen/%.pl,%,$(wildcard gen/*.pl gen/src/*.pl))
SOURCES := $(subst ~,,$(filter-out $(GEN_FILES),$(wildcard src/*.c)))
OBJECTS := $(SOURCES:src/%.c=%.o)
TESTS := sanity mob ops
TEST_SOURCES := $(TESTS:%=t/%.c)
TEST_BINARIES := $(TESTS:%=t-%)
BINARY := m0

include Config

.PHONY : build exe test clean realclean cppcheck gen list

build : $(OBJECTS)

exe : $(BINARY)

gen : $(GEN_FILES)

list :
	@$(ECHO) $(SOURCES)

test : $(TEST_BINARIES)
	$(foreach TEST,$^,./$(TEST);)

clean :
	$(RM) $(OBJECTS) $(TEST_BINARIES)

realclean : clean
	$(RM) $(GEN_FILES) $(BINARY)

cppcheck : | $(GEN_FILES)
	$(CXX) -fsyntax-only -I. $(CXXFLAGS) -xc++ $(SOURCES) $(TEST_SOURCES)

$(BINARY) : $(OBJECTS)
	$(CC) -o $@ -I. $^

$(GEN_FILES) : Config $(SPECS)

$(filter-out src/%,$(GEN_FILES)) : % : gen/%.pl ~%
	$(PERL) $< <~$@ >$@

$(filter src/%,$(GEN_FILES)) : src/% : gen/src/%.pl src/~%
	$(PERL) $< <src/~$(notdir $@) >$@

$(OBJECTS) : %.o : src/%.c m0.h
	$(CC) -c -o $@ -I. $(CFLAGS) $<

$(TEST_BINARIES) : OBJECTS := $(filter-out main.o,$(OBJECTS))
$(TEST_BINARIES) : t-% : t/%.c $(OBJECTS)
	$(CC) -o $@ -I. $(OBJECTS) $(CFLAGS) $<
