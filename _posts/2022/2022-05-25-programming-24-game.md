---
title: Taking the 24 puzzle game to the next level
tags: development c++ algorithm
redirect_from: /p/51
header:
  teaser: /image/teaser/24.png
  overlay_filter: 0.1
  overlay_image: /image/header/sunshine-1.jpg
---

The [24 game][wp] is a classic math game where players try to arrange 4 integers into 24 using basic arithmetics (addition, subtraction, multiplication and division). Thanks to its popularity, it’s now also a common intermediate-level programming practice.

Getting a program that determines whether a set of 4 numbers is solvable is easy, as there are only as many possible combinations as 4 numbers can form. Even a simple brute-force search won't take long to determine the solution. So I will go through the search algorithm and see how much improvement can be made.

## Searching for answers {#searching}

Obviously it’s not going to be a good idea to enumerate all the arrangements and search by filling in the numbers, so we’re going to think about this from bottom-up.

Starting from two numbers, it’s easy to enumerate all 4 arithmetic operators for `a?b` and `b?a`, with addition and multiplication being [commutative](https://en.wikipedia.org/wiki/Commutative_property) (i.e. `a+b` and `b+a` are identical), resulting in a total of 6 operations.

Taking this to a three-number setup. We can reduce it to the two-number case by picking two of the numbers and applying an operation. This can be generalized to an arbitrary number of inputs. As long as we’re cutting down a number at every recursion, we’ll eventually cover all possible combinations of all inputs and come to a conclusion.

With only one input number, we compare it with our search target to see if it’s an answer we want. One little note here is that [`0.1 + 0.2 != 0.3`](https://stackoverflow.com/q/588004/5958455), so floating-point number equality must be handled with caution.

I wrote my initial versions of the 24 program in Go, and here’s the snippet on recursive searching:

```go
var target float64

func CompareFloat(a, b, threshold float64) bool {
    return math.Abs(a-b) < threshold
}

func Find24(nodes []*Expression) bool {
    if len(nodes) == 1 {
        result := CompareFloat(nodes[0].value, target, 1e-6)
        if result {
            fmt.Println(nodes[0].repr, "=", target)
        }
        return result
    }
    result := false
    for i := 0; i < len(nodes); i++ {
        for j := 0; j < len(nodes); j++ {
            if i == j {
                continue
            }
            newNodes := make([]*Expression, 0, len(nodes)-1)
            for k := 0; k < len(nodes); k++ {
                if k == i || k == j {
                    continue
                }
                newNodes = append(newNodes, nodes[k])
            }
            newNodes = append(newNodes, new(Expression))
            if i < j {
                newNodes[len(nodes)-2] = JoinExpression(nodes[i], nodes[j], '+')
                result = result || Find24(newNodes)
                newNodes[len(nodes)-2] = JoinExpression(nodes[i], nodes[j], '*')
                result = result || Find24(newNodes)
            }
            newNodes[len(nodes)-2] = JoinExpression(nodes[i], nodes[j], '-')
            result = result || Find24(newNodes)
            newNodes[len(nodes)-2] = JoinExpression(nodes[i], nodes[j], '/')
            result = result || Find24(newNodes)
        }
    }
    return result
}
```

## Generating the solution {#stringify}

Without displaying the solution, the program can only get as far as a simple [LeetCode challenge](https://leetcode.com/problems/24-game/) or another online judger. For anything to make the programming quiz more suitable as a school assignment, printing out the found solution is the next thing.

Apparently just joining the numbers and the operators together is not enough, as in many cases parentheses are required to denote specific order of operations over normal operator precedence. For example, `6*2+2` is not 24, but `6*(2+2)` is. Fortunately, blindly adding parentheses works just well, though duplicate or equivalent answers would be *extremely* common. No one would think that `(1+2)+3` and `1+(2+3)` makes any sensical difference, right? That’s because addition and multiplication are [associative](https://en.wikipedia.org/wiki/Associative_property). We also need to avoid adding parentheses around plain numbers, assuming we’re not dealing with negative inputs at this moment.

By enumerating all four operators and writing rules to carefully add parentheses when needed, we have a relatively logical `JoinExpression` function.

```go
type Expression struct {
    value float64
    op    rune
    repr  string
}

func JoinExpression(e1, e2 *Expression, op rune) *Expression {
    var value float64
    var repr string
    switch op {
    case '+':
        value = e1.value + e2.value
        repr = fmt.Sprintf("%s+%s", e1.repr, e2.repr)
    case '-':
        value = e1.value - e2.value
        rhs := e2.repr
        if e2.op == '+' || e2.op == '-' {
            rhs = fmt.Sprintf("(%s)", e2.repr)
        }
        repr = fmt.Sprintf("%s-%s", e1.repr, rhs)
    case '*':
        value = e1.value * e2.value
        lhs := e1.repr
        if e1.op == '+' || e1.op == '-' {
            lhs = fmt.Sprintf("(%s)", e1.repr)
        }
        rhs := e2.repr
        if e2.op == '+' || e2.op == '-' {
            rhs = fmt.Sprintf("(%s)", e2.repr)
        }
        repr = fmt.Sprintf("%s*%s", lhs, rhs)
    case '/':
        value = e1.value / e2.value
        lhs := e1.repr
        if e1.op == '+' || e1.op == '-' {
            lhs = fmt.Sprintf("(%s)", e1.repr)
        }
        rhs := e2.repr
        if e2.op == '+' || e2.op == '-' || e2.op == '*' || e2.op == '/' {
            rhs = fmt.Sprintf("(%s)", e2.repr)
        }
        repr = fmt.Sprintf("%s/%s", lhs, rhs)
    }
    return &Expression{value: value, op: op, repr: repr}
}
```

Since plain numbers never need parantheses, their “operator” is assigned to a single dot (or any character not used in the code).

At this point, all that’s missing for a complete program is a `main()` function. To add a little bit of flexibility of changing the target value, I used Go’s standard library `flag` for parsing command-line arguments, though only a single option is needed now.

To avoid generating the same answer for any particular set of inputs, I shuffled the input numbers before doing the search.

```go
func main() {
    flag.Float64Var(&target, "t", 24.0, "target value")
    flag.Parse()

    nums := make([]*Expression, len(flag.Args()))
    for i, arg := range flag.Args() {
        value, err := strconv.ParseFloat(arg, 64)
        if err != nil {
            panic(err)
        }
        nums[i] = &Expression{value: value, op: '.', repr: arg}
    }

    rand.Seed(time.Now().UnixNano())
    for i := range nums {
        j := rand.Intn(i + 1)
        nums[i], nums[j] = nums[j], nums[i]
    }

    if !Find24(nums) {
        fmt.Println("No solution")
    }
}
```

<div class="notice--primary" markdown="1">
The complete program can be found [here](https://gist.github.com/iBug/62610c759f7702071baaf884301ae067) and is ready to compile & run.

This program can output lines among `(1+3)*(2+4) = 24` and `1*2*3*4 = 24`, which looks good so far.
</div>

## Next level: Reducing duplicate answers {#next-level}

It’s easy to add a “show all answers” flag:

```go
var allAnswers bool

func main() {
    flag.BoolVar(&allAnswers, "a", false, "find all solutions")
}
```

And replace all `return result` with `return result && !allAnswers` so that short-circuit expressions continue to run after finding an answer.

It does, however, prints a *lot* of redundant answers:

```
1*2*4*3 = 24
1*3*2*4 = 24
1*3*2*4 = 24
1*4*2*3 = 24
1*4*2*3 = 24
2*1*4*3 = 24
2*1*4*3 = 24
2*3*1*4 = 24
2*3*1*4 = 24
```

Under the hood it could just be `(1*4)*(2*3)` and `1*(4*(2*3))`, which we don’t know for sure since we only omitted the parentheses.

### Redesigning data structure {#data-structures}

We could fix this by flattening expressions so each addition and multiplication operator can have multiple operands. This also enables reliable sorting of elements, which is also pretty obvious.

There’s still more. We need to handle nested negativity. For example, `1-2+3` and `1-(2-3)` are really no different, and special care is to be taken when flattening. It also poses the challenge of sorting elements with mixed signs, as well as when parenthesizing them.

To keep the logic straightforward, instead of binary trees, we can use lists to store the operands. Subtracted elements can then be stored in another list under the same “group of additions”, and likewise is division. Finally, plain numbers still require their specialized handling.

```go
type Expression interface {
    Value() float64
    Repr() string
}

type AddGroup struct {
    Pos []Expression
    Neg []Expression
}

type MulGroup struct {
    Pos []Expression
    Neg []Expression
}

type Number struct {
    Val float64
    Str string
}
```

Sorting is easy as long as there’s a well-defined “order”:

```go
func CompareExpression(e1, e2 Expression) bool {
    if e1.Value() < e2.Value() {
        return true
    }
    if e1.Value() > e2.Value() {
        return false
    }
    return strings.Compare(e1.Repr(), e2.Repr()) < 0
}

func SortExpression(e []Expression) {
    sort.Slice(e, func(i, j int) bool {
        return CompareExpression(e[i], e[j])
    })
}
```

Calculating the value is also easy:

```go
func (e *AddGroup) Value() float64 {
    var s float64 = 0
    for _, ee := range e.Pos {
        s += ee.Value()
    }
    for _, ee := range e.Neg {
        s -= ee.Value()
    }
    return s
}

func (e *MulGroup) Value() float64 {
    var s float64 = 1
    for _, ee := range e.Pos {
        s *= ee.Value()
    }
    for _, ee := range e.Neg {
        s /= ee.Value()
    }
    return s
}
```

Generating representations for expressions has also been made easier and more consistent, as we no longer need to add parentheses for additions around subtractions, or multiplications around divisions. We only need parentheses around “groups of addition” among “groups of multiplication”. To ensure consistency, sort the expressions before producing strings.

```go
func (e *AddGroup) Repr() string {
    SortExpression(e.Pos)
    SortExpression(e.Neg)
    var s strings.Builder
    for _, ee := range e.Pos {
        s.WriteString("+" + ee.Repr())
    }
    for _, ee := range e.Neg {
        s.WriteString("-" + ee.Repr())
    }
    return s.String()[1:]
}

func (e *MulGroup) Repr() string {
    SortExpression(e.Pos)
    SortExpression(e.Neg)
    var s strings.Builder
    for _, ee := range e.Pos {
        if _, ok := ee.(*Number); ok {
            s.WriteString("*" + ee.Repr())
        } else {
            s.WriteString("*(" + ee.Repr() + ")")
        }
    }
    for _, ee := range e.Neg {
        if _, ok := ee.(*Number); ok {
            s.WriteString("/" + ee.Repr())
        } else {
            s.WriteString("/(" + ee.Repr() + ")")
        }
    }
    return s.String()[1:]
}
```

Joining two elements into a new expression is now a little bit more complex, since we want to avoid nesting the same kind of groups. We need to check the types of the joining operands to determine whether we should append as a single element, or extract the lists and concatenate them. This also helps ensure that every group has at least one “positive” element, so it doesn’t begin with a minus sign or division.

```go
func JoinAddGroup(e1, e2 Expression, neg2 bool) *AddGroup {
    e := new(AddGroup)
    if a1, ok := e1.(*AddGroup); ok {
        e.Pos = append(e.Pos, a1.Pos...)
        e.Neg = append(e.Neg, a1.Neg...)
    } else {
        e.Pos = append(e.Pos, e1)
    }
    if a2, ok := e2.(*AddGroup); ok {
        if neg2 {
            e.Pos = append(e.Pos, a2.Neg...)
            e.Neg = append(e.Neg, a2.Pos...)
        } else {
            e.Pos = append(e.Pos, a2.Pos...)
            e.Neg = append(e.Neg, a2.Neg...)
        }
    } else {
        if neg2 {
            e.Neg = append(e.Neg, e2)
        } else {
            e.Pos = append(e.Pos, e2)
        }
    }
    return e
}
```

A `neg2` switch is provided to determine between `e1+e2` and `e1-e2` as we don’t want separate code for handling subtraction.

The exact same code is used for `JoinMulGroup` with only the types replaced. (This is why I switched to C++ after this point: Function templates are much more friendly for this kind of repeated logic.)

### Deduplicating

With reliable expression flattening and sorting in place, we can now deduplicate results by comparing string representation:

```go
var answers []string

func EvalResult(e Expression) bool {
    result := CompareFloat(e.Value(), target, 1e-6)
    if result {
        s := e.Repr()
        duplicate := false
        for _, ans := range answers {
            if ans == s {
                duplicate = true
                break
            }
        }
        if !duplicate {
            fmt.Println(s, "=", target)
            answers = append(answers, s)
        }
    }
    return result && !allAnswers
}
```

This is about as far as the new data structure can bring us. The current program handles structural duplicates very well: Running on input `1 2 3 4` produces only 4 results:

```
4*(1+2+3) = 24
1*2*3*4 = 24
2*3*4/1 = 24
(1+3)*(2+4) = 24
```

The complete code so far can be found [here](https://gist.github.com/iBug/b0e3d7dc11e53ac53df5f6d0438ad3b5).
{: .notice--primary }

## Advanced level: More deduplication, and optimization {#advanced}

On a side note, I switched to C++ at this point because I found Go’s comprehensive runtime *cumbersome*, and its lack of compiler optimization is specifically detrimental for such computing tasks. C++ has everything I need, including dynamic arrays (`vector`), dynamic typing (RTTI via `virtual` functions and `dynamic_cast`) and hash sets (`unordered_set`). C++ also has the advantage of supporting function templates and inheritance, which helps greatly with duplicate logic. The only thing missing from Go is a standard library for parsing command-line arguments, which bothers very little as I don’t need complex parsing rules. (There are external libraries that I want to avoid, such as POSIX `getopt()`.)

### Switching to C++ {#cpp}

To mimic the `Expression` interface in Go, I created an abstract base class:

```cpp
struct Expression {
    virtual ~Expression() {}
    virtual void normalize() {}
    virtual operator string() const = 0;
    virtual operator double() const = 0;
};
```

I also took this chance to separate `string()` from `normalize()`, since they really could do different things and not necessarily together.

The additive group and multiplicative group can also have some commonalities extracted into a new base class, to allow even more shared code.

```cpp
struct ExpressionGroup : Expression {
    vector<Expression*> positive;
    vector<Expression*> negative;

    void normalize() override {
        for (auto& e : positive)
            e->normalize();
        for (auto& e : negative)
            e->normalize();
        sort_expressions(positive);
        sort_expressions(negative);
    }
};

template <typename T>
T* join_group(Expression* a, Expression* b, bool negative) {
    static_assert(std::is_base_of<ExpressionGroup, T>::value,
                  "T must be derived from ExpressionGroup");
    // implementation
}

inline AdditiveGroup*
join_additive_group(Expression* a,
                    Expression* b,
                    bool negative) {
    return join_group<AdditiveGroup>(a, b, negative);
}

inline MultiplicativeGroup*
join_multiplicative_group(Expression* a,
                          Expression* b,
                          bool negative) {
    return join_group<MultiplicativeGroup>(a, b, negative);
}
```

### Double-negativity in multiplicative groups {#double-negativity}

When fed with input `1 1 4 9`, the above Go program produces 2 results:

```
(4-1)*(9-1) = 24
(1-9)*(1-4) = 24
```

To fix this, we examine how many additive groups that can be “inverted” under a multiplicative group, and invert them in pairs.

We consider an additive group *invertible* if it evaluates to a negative value and has at least one subtracted element:

```cpp
struct Expression {
    virtual void invert() {}
    virtual bool is_invertible() const { return false; }
};

struct ExpressionGroup : Expression {
    bool is_invertible() const override {
        return !negative.empty();
    }
};

struct AdditiveGroup : ExpressionGroup {
    void invert() override {
        std::swap(positive, negative);
    }

    bool is_invertible() const override {
        return double(*this) < 0 && this->ExpressionGroup::is_invertible();
    }
};
```

Note that the default implementation for `invert()` and `is_invertible()` applies to plain numbers as they can’t just grab a minus sign and become inverted.

Now we have the necessary APIs for fixing multiplicative groups:

```cpp
void MultiplicativeGroup::normalize() override {
    int neg_count = 0;
    for (const auto& e : positive)
        neg_count += e->is_invertible();
    for (const auto& e : negative)
        neg_count += e->is_invertible();
    neg_count -= neg_count % 2;
    for (const auto& e : negative)
        if (neg_count == 0)
            break;
        else if (e->is_invertible()) {
            e->invert();
            neg_count--;
        }
    for (const auto& e : positive)
        if (neg_count == 0)
            break;
        else if (e->is_invertible()) {
            e->invert();
            neg_count--;
        }
    this->ExpressionGroup::normalize();
}
```

Because normalization doesn’t change the value of an expression, we call it only when we need a string representation. This means we can normalize after determining whether it’s a solution.

```cpp
std::unordered_set<string> answers;

bool eval_result(Expression* node) {
    bool result = is_equal(*node, target);
    if (result) {
        node->normalize();
        auto expr = string(*node);
        auto is_new_answer = answers.insert(expr).second;
        if (is_new_answer)
            std::cout << expr << " = " << target << std::endl;
    }
    return result;
}
```

### Subtracting negative values {#negative-subtraction}

When fed with input `1 1 4 9`, the above Go program produces 7 results, among which are these two:

```
4+(7-3)*5 = 24
4-(3-7)*5 = 24
```

Apparently they are no more than a pair of `a+b` and `a-(-b)` variants. The latter form is just boring.

Now, in addition to additive groups, we need to implement inversion for multiplicative groups as well. This one isn’t hard either, just iterate through its children and see if any of them is invertible:

```cpp
struct MultiplicativeGroup : ExpressionGroup {
    bool is_invertible() const override {
        if (double(*this) >= 0)
            return false;
        for (const auto& e : positive)
            if (e->is_invertible())
                return true;
        for (const auto& e : negative)
            if (e->is_invertible())
                return true;
        return false;
    }

    void invert() override {
        for (const auto& e : negative)
            if (e->is_invertible()) {
                e->invert();
                return;
            }
        for (const auto& e : positive)
            if (e->is_invertible()) {
                e->invert();
                return;
            }
    }
};
```

We also have extra things to do than sorting when normalizing an additive group. That is, to move all invertible children from the negative list to the positive list, inverting all involved.

```cpp
void AdditiveGroup::normalize() override {
    for (auto it = negative.begin(); it != negative.end();) {
        auto& e = *it;
        if (e->is_invertible()) {
            e->invert();
            positive.push_back(e);
            it = negative.erase(it);
        } else {
            ++it;
        }
    }
    this->ExpressionGroup::normalize();
}
```

### Substracting zeros and dividing by ones {#identity-elements}

Zero is the [identity element](https://en.wikipedia.org/wiki/Identity_element) of addition, and one is that of multiplication. This means `a+0=a-0=a` and `a*1=a/1=a`. We can normalize `-0` into `+0` and `/1` into `*1`. This one’s even easier since it only moves elements from the negative list to the positive list.

```cpp
void AdditiveGroup::normalize() override {
    // ...
    else if (is_equal(*e, 0.0)) {
        positive.push_back(e);
        it = negative.erase(it);
    }
    // ...
} 
```

For multiplicative groups, we can go one step further and take care of `/(-1)` as well:

```cpp
void MultiplicativeGroup::normalize() override {
    // ...
    for (auto it = negative.begin(); it != negative.end();) {
        auto& e = *it;
        if (is_equal(*e, 1.0) || is_equal(*e, -1.0)) {
            positive.push_back(e);
            it = negative.erase(it);
        } else {
            ++it;
        }
    }
    // ...
}
```

### Memoizing intermediate results {#memoization}

For small inputs like only 4 numbers, there are only up to 36×18×6=3,888 leaf nodes to search, so any working algorithm shouldn’t run for more than tens of milliseconds. But why limit to 4 input numbers, a pretty artificial value, when the algorithm is designed to scale and handle inputs of any sizes?

With 8 input numbers, the latest Go program runs from 20 seconds to more than a minute. It’s easily imaginable that there are a lot of duplicate intermediate search nodes, like `(a+b) (c+d)` and `(c+d) (a+b)`. Searching further down these states wastes a lot of time. Given that we already have normalization and sorting facilities, it’s straightforward to serialize an intermediate state, save it in a set, and prune repeated search branches.

```cpp
std::unordered_set<string> states;

bool dedup_state(const vector<Expression*>& nodes) {
    if (!use_states)
        return false;
    auto n = nodes;
    sort_expressions(n);
    stringstream ss;
    for (auto& e : n) {
        e->normalize();
        ss << ":" << string(*e);
    }
    return !states.insert(ss.str()).second;
}
```

Then at the beginning of the recursive `search()` function, right after the evaluation branch, we add the pruning logic:

```cpp
bool search(const vector<Expression*>& nodes) {
    if (nodes.size() == 1)
        return eval_result(nodes[0]) && !all_answers;
    if (dedup_state(nodes))
        return false;
```

My testing shows that this optimization brings a speedup of 1.5× to 2×, depending on input pattern. On extreme cases like 8 ones, the speedup even goes over 4×.

Finally, to use the right tool for the right job:

```cpp
use_states = nums.size() >= 5;
```

Because generating and hashing strings could be expensive, and there aren’t enough duplicates for small inputs, I chose to enable mid-way deduplication only for inputs with 5 or more numbers.

### Placement of zeros and ones {#placement}

The last thing to handle is the placement of no-ops, like `*1` and `+3-3`. While it could be arithmetically different between `a+b-b` and `a*b/b`, or between `a*1+b` and `(a+b)*1`, one would think the difference is minimal when playing with cards in reality.

Taking the same convention as on the [*4 Numbers*](https://www.4nums.com/theory/) website, points 7 and 8, the following rules is defined as “preferences for duplicates”:

- Multiplying by ±1 happens on the topmost multiplication group, so `1*2+3*4` becomes `1*(2+3*4)`, except when there’s a pair of additive no-ops: `(a+b)*1+c-c` is preferred over `(a+b+c-c)*1`.
- A pair of same numbers cancelling each other must be done with addition and subtraction, and must happen at the topmost layer, so `a*b/b+c` becomes `a+c+b-b`. This applies to ones.

Now put them into code. If we try to fix it the same way as normalizing, there’s a fundamental difference from previous deduplication methods: The other normalization don’t modify the components (structurally) but only move them around, while the handling of zeros and ones will have to extract numbers from sub-expressions and place them elsewhere. This breaks two things:

- The searching algorithm assumes numbers and expressions aren’t modified in recursions. Continuing to do so might cause the search to miss potential solutions.
- After cleaning up `shared_ptr`s, memory allocation is handled manually. Breaking the existing tree structure makes tracking objects *much* harder, and it’s easier to reach a memory leak or whatever.

So I had to give up normalizing this one. But there must be a solution.

Turning our attention back to the recursive searching. It performs a comprehensive enumeration of possible combinations of every pair of numbers, and therefore must be able to form every possible expression tree from the given numbers.

Right, we could just define the “canonical forms” and reject solutions coming in non-canonical forms.

Starting off with the base form. The sole boolean argument is necessary because certain structures should live in the top layer, and they need special treatment.

```cpp
struct Expression {
    virtual bool is_canonical(bool is_top_level = true) const { return true; }
};
```

Obviously for plain numbers there’s nothing we can do, so this virtual function is not overridden for `struct Number`.

Now for the expression groups. Recursive checking is required, and more specific rules are to be provided by further overrides in the two kinds of specialized groups.

```cpp
struct ExpressionGroup : Expression {
    bool has_negative_pairs() const {
        for (auto& e1 : positive)
            for (auto& e2 : negative)
                if (is_equal(double(*e1), double(*e2)))
                    return true;
        return false;
    }

    bool is_canonical(bool is_top_level = true) const override {
        for (auto& e : positive)
            if (!e->is_canonical(false))
                return false;
        for (auto& e : negative)
            if (!e->is_canonical(false))
                return false;
        return true;
    }
};
```

The extra function is provided as a helper to shorten specialized code for descendants.

Multiplicative groups are easier to deal with: A top-level MG permits multiplying by ones, but only a single one.

```cpp
bool MultiplicativeGroup::is_canonical(bool allow_ones = true) const override {
    if (!ExpressionGroup::is_canonical(allow_ones))
        return false;
    int ones = 0;
    for (const auto& e : positive)
        ones += is_equal(*e, 1.0);
    if (!allow_ones && ones >= 1)
        return false;
    if (ones >= 2)
        return false;
    return !has_negative_pairs();
}
```

Additive groups are a bit complicated, as they could contain a (technically) second-level MG while still permitting them to have multiply-by-ones. So instead of calling their `is_canonical()` with `false`, the argument should be inherited from the AG itself.

```cpp
bool AdditiveGroup::is_canonical(bool is_top_level) const {
    if (is_top_level) {
        for (auto& e : positive)
            if (!e->is_canonical(dynamic_cast<MultiplicativeGroup*>(e) != nullptr))
                return false;
        for (auto& e : negative)
            if (!e->is_canonical(dynamic_cast<MultiplicativeGroup*>(e) != nullptr))
                return false;
        }
        return true;
    }
    if (!ExpressionGroup::is_canonical(is_top_level))
        return false;
    return !has_negative_pairs();
}
```

Unfortunately, this is practically ineffective. Solutions like `1*4+4*5` keep popping up. The missing details are:

- A sub-MG inherits its top-level-like behavior if it’s the only MG among all children of a top-level AG
- An AG permits a top-level child MG if it’s otherwise a no-op. For example, `24*1+5-5` but not `8*1+8+8`

For the first point, we need to count all children and see how many of them are MGs, and for the second point we can check if the value of the AG equals to its only child MG. So wrap that up:

```cpp
if (mg_count == 1 && is_equal(*this, *mg)) { ... }
```

Now the program is correctly reporting that `1 8 8 8` has a single solution `(8+8+8)*1`, except that it stops producing solutions for `5 6 7 7`.

Notice that the only solution is `(5-7/7)*6`, and that we’re rejecting instead of normalizing this kind of “non-canonical” forms. The problem is that `7/7` acts as a concrete one for subtraction, instead of a no-op. Should have checked if there are other operands for multiplying…

```cpp
return !(positive.size() > 1 && has_negative_pairs());
```

The program is still reporting “No solutions” for `1 5 5 5`, which has the same root cause. In the sole solution `(5-1/5)*5`, the 1 in the MG doesn’t act as a no-op, either. Time to wrap up with another guard.

```cpp
if (positive.size() > 1) { /* check for ones */ }
```

## Postface

The *4 Numbers* website provides a comprehensive list of all 1362 solvable quadruples from 1 to 13 (i.e. formed with a standard 52-card set). Just grab the page and do some HTML processing, and a good test suite is readily available.

[Here][gist-cpp]’s the final version of the C++ code. It gives solutions to 1362 test cases where all of them are identical to those on the *4 Numbers* website.

The problem originates from a course *Program Design II* where a friend of mine works as a TA this semester.

## References

- [24 (puzzle) - Wikipedia][wp]
- [Definition of "distinct" by *4 Numbers* website][4nums]


  [wp]: https://en.wikipedia.org/wiki/24_(puzzle)
  [4nums]: https://www.4nums.com/theory/
  [gist-cpp]: https://gist.github.com/iBug/ea958ca7f1270128d58b5176858d71cb
