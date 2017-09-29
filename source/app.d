/* library code */


/++
 Referrence:
 - https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm#Using_a_priority_queue
 - http://shifth.hatenablog.com/entry/2015/05/31/104829
 +/
auto dijkstra(alias distfun, E, V)(E[V[2]] tree, V start) {
    import std.container : Array, PriorityQueue = BinaryHeap;

    // initalize return dict
    alias D = typeof(distfun(E.init));
    struct Path {
        D cost;
        V[] path;
    }
    Path[V] distDict;
    foreach (key; tree.byKey()) {
        distDict[key[1]] = Path(D.max, []);
    }
    distDict[start] = Path(0, [start]);

    // priority_queue
    struct Edge {
        V to;
        D cost;
    }
    auto queue = new PriorityQueue!(Array!Edge, "a.cost > b.cost");
    queue.insert(Edge(start,0));

    // TODO: why foreach cannot be used?
    // foreach (edge; queue) {
    for (; !queue.empty; queue.popFront()) {
        auto edge = queue.front();
        auto v = edge.to;
        auto cost = edge.cost;
        // another shorter path was already found, skip
        if (distDict[v].cost < cost)
            continue;

        foreach (key, val; tree) {
            if (key[0] == v) {
                Edge e = { to: key[1], cost: distfun(val) };
                if (distDict[v].cost + e.cost < distDict[e.to].cost) {
                    distDict[e.to] = Path(distDict[v].cost + e.cost, distDict[v].path ~ e.to);
                    // found new shorter path, push to queue for re-calculate path
                    queue.insert(Edge(e.to, distDict[e.to].cost));
                }
            }
        }
    }
    return distDict;
}


unittest {
    /*

     a__3_b__1__d
       \   \5    \1
        \_4_\c__2_\_e

     */
    enum V { a, b, c, d, e }
    int[V[2]] tree = [
        [V.a, V.b]: 3,
        [V.a, V.c]: 4,
        [V.b, V.c]: 5,
        [V.b, V.d]: 1,
        [V.c, V.e]: 2,
        [V.d, V.e]: 1
    ];
    auto dists = tree.dijkstra!(i => i)(V.a);
    assert(dists[V.a].cost == 0 && dists[V.a].path == [V.a]);
    assert(dists[V.b].cost == 3 && dists[V.b].path == [V.a, V.b]);
    assert(dists[V.c].cost == 4 && dists[V.c].path == [V.a, V.c]);
    assert(dists[V.d].cost == 4 && dists[V.d].path == [V.a, V.b, V.d]);
    assert(dists[V.e].cost == 5 && dists[V.e].path == [V.a, V.b, V.d, V.e]);
}


// TODO: support bidirectional list
struct AdjencyList(Vertex, Edge, Graph) {
    import std.format : format;
    Graph graph;
    enum Bundle { graph };

    struct VertexKey {
        size_t value;
        alias value this;
    }
    size_t nVertex = 0;
    Vertex[VertexKey] vertexDict;

    alias EdgeKey = VertexKey[2];
    Edge[EdgeKey] edgeDict;


    ref auto opIndex(Bundle b) {
        if (b == Bundle.graph) {
            return this.graph;
        }
        else {
            throw new Error("index %s not found!".format(b));
        }
    }

    ref auto opIndex(VertexKey vkey) {
        if (vkey !in this.vertexDict) {
            this.vertexDict[vkey] = Vertex();
        }
        return this.vertexDict[vkey];
    }

    ref auto opIndex(EdgeKey ekey) {
        if (ekey !in this.edgeDict) {
            this.edgeDict[ekey] = Edge();
        }
        return this.edgeDict[ekey];
    }

    auto addVertex() {
        return VertexKey(nVertex++);
    }

    auto addEdge(VertexKey v1, VertexKey v2) {
        import std.algorithm : sort;

        if (v1 !in vertexDict || v2 !in vertexDict) {
            throw new Error("Vertex key not found");
        }

        EdgeKey e = [v1, v2]; // (v1 < v2 ? [v1, v2] : [v2, v1]);
        if (e in edgeDict) {
            throw new Error("Vertex key paier is already defined");
        }

        return e;
    }

    @property
    auto toString() {
        string s = "%s {\n".format(graph);
        foreach (vs, e; edgeDict) {
            s ~= "  %s: %s -> %s\n".format(e, vertexDict[vs[0]], vertexDict[vs[1]]);
        }
        s ~= "}";
        return s;
    }
}


auto shortestPaths(alias WeightFun, AL)(AL map, AL.VertexKey start) {
    return dijkstra!(a => a.distance)(map.edgeDict, start);
}


/* user code */

struct City {
    string name;
    int population;
    int[] zipcodes;
}

struct Highway {
    string name;
    double distance;
}

struct Country {
    string name;
}

alias Map = AdjencyList!(City, Highway, Country);


void main() {
    import std.stdio : writefln, writeln;

    // https://boostjp.github.io/tips/graph.html#bundle-property
    Map map;
    map[Map.Bundle.graph].name = "Japan";
    assert(map.graph.name == "Japan");

    auto v1 = map.addVertex();
    auto v2 = map.addVertex();
    map[v1].name = "Tokyo";
    map[v1].population = 13221169;
    map[v1].zipcodes ~= 1500013;

    map[v2].name = "Nagoya";
    map[v2].population = 2267048;
    map[v2].zipcodes ~= 4600006;

    // add vertex
    auto e = map.addEdge(v1, v2);
    map[e].name = "Tomei Expessway";
    map[e].distance = 325.5;

    auto distance = map.shortestPaths!(a => a.distance)(v1);
    auto path = distance[v2].path;
    writefln("Tokyo-Nagoya : %s km (%s)", distance[v2].cost, map.edgeDict[[path[0], path[1]]]);
    map.writeln;
}
