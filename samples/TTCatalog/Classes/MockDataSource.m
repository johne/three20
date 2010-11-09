
#import "MockDataSource.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MockAddressBook

@synthesize names = _names, fakeSearchDuration = _fakeSearchDuration;

///////////////////////////////////////////////////////////////////////////////////////////////////
// class public

+ (NSMutableArray*)fakeNames {
  return [NSMutableArray arrayWithObjects:
  @"William Wilson",
  @"Stephen Canady",
  @"Elaine Ruth",
  @"Marcus Martin",
  @"Aileen Kemp",
  @"Kevin Maupin",
  @"Martha Vanwinkle",
  @"Kelly Munk",
  @"Lisa Rosato",
  @"Marcella Jett",
  @"Barbara Murphy",
  @"Edward Sherrod",
  @"Jane Cushing",
  @"Clara Sims",
  @"Velma Moreno",
  @"Eric Noguera",
  @"Shirley Williams",
  @"Gina Millard",
  @"Edward Deputy",
  @"Jennifer Myers",
  @"Mary Spurgeon",
  nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)fakeSearch:(NSString*)text {
  self.names = [NSMutableArray array];

  if (text.length) {
    text = [text lowercaseString];
    for (NSString* name in _allNames) {
      if ([[name lowercaseString] rangeOfString:text].location == 0) {
        [_names addObject:name];
      }
    }
  }

  [_delegates perform:@selector(modelDidFinishLoad:) withObject:self];
}

- (void)fakeSearchReady:(NSTimer*)timer {
  _fakeSearchTimer = nil;

  NSString* text = timer.userInfo;
  [self fakeSearch:text];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithNames:(NSArray*)names {
  if (self = [super init]) {
    _delegates = nil;
    _allNames = [names copy];
    _names = nil;
    _fakeSearchTimer = nil;
    _fakeSearchDuration = 0;
  }
  return self;
}

- (void)dealloc {
  TT_INVALIDATE_TIMER(_fakeSearchTimer);
  TT_RELEASE_SAFELY(_delegates);
  TT_RELEASE_SAFELY(_allNames);
  TT_RELEASE_SAFELY(_names);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTModel

- (NSMutableArray*)delegates {
  if (!_delegates) {
    _delegates = TTCreateNonRetainingArray();
  }
  return _delegates;
}

- (BOOL)isLoadingMore {
  return NO;
}

- (BOOL)isOutdated {
  return NO;
}

- (BOOL)isLoaded {
  return !!_names;
}

- (BOOL)isLoading {
  return !!_fakeSearchTimer;
}

- (BOOL)isEmpty {
  return !_names.count;
}

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
}

- (void)invalidate:(BOOL)erase {
}

- (void)cancel {
  if (_fakeSearchTimer) {
    TT_INVALIDATE_TIMER(_fakeSearchTimer);
    [_delegates perform:@selector(modelDidCancelLoad:) withObject:self];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (void)loadNames {
  TT_RELEASE_SAFELY(_names);
  _names = [_allNames mutableCopy];
}

- (void)search:(NSString*)text {
  [self cancel];

  if (text.length) {
    if (_fakeSearchDuration) {
      TT_INVALIDATE_TIMER(_fakeSearchTimer);
      _fakeSearchTimer = [NSTimer scheduledTimerWithTimeInterval:_fakeSearchDuration target:self
                                selector:@selector(fakeSearchReady:) userInfo:text repeats:NO];
      [_delegates perform:@selector(modelDidStartLoad:) withObject:self];
    } else {
      [self fakeSearch:text];
      [_delegates perform:@selector(modelDidFinishLoad:) withObject:self];
    }
  } else {
    TT_RELEASE_SAFELY(_names);
    [_delegates perform:@selector(modelDidChange:) withObject:self];
  }
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MockDataSource

@synthesize addressBook = _addressBook;

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
  if (self = [super init]) {
    _addressBook = [[MockAddressBook alloc] initWithNames:[MockAddressBook fakeNames]];
    [_addressBook loadNames];
    self.model = _addressBook;
  }
  return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_addressBook);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewDataSource

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView {
  return [TTTableViewDataSource lettersForSectionsWithSearch:YES summary:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTTableViewDataSource

- (void)tableViewDidLoadModel:(UITableView*)tableView {
  self.items = [NSMutableArray array];
  self.sections = [NSMutableArray array];

  NSMutableDictionary* groups = [NSMutableDictionary dictionary];
  for (NSString* name in _addressBook.names) {
    NSString* letter = [NSString stringWithFormat:@"%c", [name characterAtIndex:0]];
    NSMutableArray* section = [groups objectForKey:letter];
    if (!section) {
      section = [NSMutableArray array];
      [groups setObject:section forKey:letter];
    }

    TTTableItem* item = [TTTableTextItem itemWithText:name URL:nil];
    [section addObject:item];
  }

  NSArray* letters = [groups.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
  for (NSString* letter in letters) {
    NSArray* items = [groups objectForKey:letter];
    [_sections addObject:letter];
    [_items addObject:items];
  }
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MockSearchDataSource

@synthesize addressBook = _addressBook;

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithDuration:(NSTimeInterval)duration {
  if (self = [super init]) {
    _addressBook = [[MockAddressBook alloc] initWithNames:[MockAddressBook fakeNames]];
    _addressBook.fakeSearchDuration = duration;
    self.model = _addressBook;
  }
  return self;
}

- (id)init {
  return [self initWithDuration:0];
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_addressBook);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTTableViewDataSource

- (void)tableViewDidLoadModel:(UITableView*)tableView {
  self.items = [NSMutableArray array];

  for (NSString* name in _addressBook.names) {
    TTTableItem* item = [TTTableTextItem itemWithText:name URL:@"http://google.com"];
    [_items addObject:item];
  }
}

- (void)search:(NSString*)text {
  [_addressBook search:text];
}

- (NSString*)titleForLoading:(BOOL)reloading {
  return @"Searching...";
}

- (NSString*)titleForNoData {
  return @"No names found";
}

@end
