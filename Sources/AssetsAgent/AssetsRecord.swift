import GraniteAgents

/// The assets agent's place in Granite's roster: an app that links this package finds the `assets` agent by this
/// record, with nothing listed by hand.
@used @section("__DATA_CONST,__granite")
let assetsRecord: GraniteRoster.Record = { GraniteRoster.record(AssetsAgent.self) }
