# Graph Report - hash_color_avatar_elixir  (2026-06-29)

## Corpus Check
- 7 files · ~2,316 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 44 nodes · 56 edges · 10 communities (8 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b389a521`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]

## God Nodes (most connected - your core abstractions)
1. `HashColorAvatar` - 16 edges
2. `gen_avatar()` - 9 edges
3. `hsv_to_rgb()` - 6 edges
4. `HashColorAvatar.MixProject` - 5 edges
5. `set_color()` - 5 edges
6. `Usage` - 5 edges
7. `random_color()` - 4 edges
8. `HashColorAvatar` - 4 edges
9. `project()` - 3 edges
10. `normalize_hue()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `gen_avatar()` --calls--> `random_color()`  [EXTRACTED]
  lib/hash_color_avatar.ex → lib/hash_color_avatar.ex  _Bridges community 3 → community 1_
- `hsv_to_rgb()` --calls--> `clamp_float()`  [EXTRACTED]
  lib/hash_color_avatar.ex → lib/hash_color_avatar.ex  _Bridges community 5 → community 3_

## Communities (10 total, 2 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.18
Nodes (11): code:elixir (iex> HashColorAvatar.get_initial("guruh soekarno putra")), code:elixir (iex> HashColorAvatar.get_initial("")), code:elixir (svg = HashColorAvatar.gen_avatar("Marlyn Monroe") |> to_stri), code:elixir (iex> HashColorAvatar.gen_avatar("Marlyn Monroe") |> to_strin), code:elixir (iex> HashColorAvatar.random_color(saturation: 70, value: 100), code:elixir (iex> HashColorAvatar.set_color(12)), `gen_avatar/2`, `get_initial/1` (+3 more)

### Community 1 - "Community 1"
Cohesion: 0.39
Nodes (8): HashColorAvatar, gen_avatar(), get_initial(), minihash(), normalize_shape(), normalize_style(), normalize_text(), validate_size!()

### Community 2 - "Community 2"
Cohesion: 0.47
Nodes (4): HashColorAvatar.MixProject, deps(), package(), project()

### Community 3 - "Community 3"
Cohesion: 0.47
Nodes (6): get_rgb_color(), hsv_to_rgb(), normalize_hue(), random_color(), rgb_to_hex(), set_color()

### Community 4 - "Community 4"
Cohesion: 0.40
Nodes (4): code:elixir (def deps do), Features, HashColorAvatar, Installation

## Knowledge Gaps
- **9 isolated node(s):** `HashColorAvatarTest`, `Features`, `code:elixir (def deps do)`, `code:elixir (iex> HashColorAvatar.get_initial("guruh soekarno putra"))`, `code:elixir (iex> HashColorAvatar.get_initial(""))` (+4 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Usage` connect `Community 0` to `Community 4`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **Why does `HashColorAvatar` connect `Community 1` to `Community 3`, `Community 5`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **Why does `HashColorAvatar` connect `Community 4` to `Community 0`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **What connects `HashColorAvatarTest`, `Features`, `code:elixir (def deps do)` to the rest of the system?**
  _9 weakly-connected nodes found - possible documentation gaps or missing edges._