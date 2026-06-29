//
//  TeamCompositionsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct TeamCompositionsViewModelTests {
  @Test
  func loadIfNeeded_skipsWhenAlreadyLoadedForTeam() async {
    var didFetch = false
    let compositionService = MockCompositionService()
    compositionService.fetchTeamCompositionsHandler = { _ in
      didFetch = true
      return []
    }
    let host = TeamTestSupport.makeHost(compositionService: compositionService)
    host.compositionsViewModel.compositionsLoadedForTeamId = "team-admin"

    await host.compositionsViewModel.loadIfNeeded()

    #expect(didFetch == false)
    #expect(host.compositionsViewModel.compositions.isEmpty)
  }

  @Test
  func loadIfNeeded_loadsCompositionsForSelectedTeam() async {
    let composition = TeamComposition(id: "comp-1", name: "Titulaires", teamId: "team-admin")
    let compositionService = MockCompositionService()
    compositionService.fetchTeamCompositionsHandler = { teamId in
      #expect(teamId == "team-admin")
      return [composition]
    }
    let host = TeamTestSupport.makeHost(compositionService: compositionService)

    await host.compositionsViewModel.loadIfNeeded(force: true)

    #expect(host.compositionsViewModel.compositions == [composition])
    #expect(host.compositionsViewModel.compositionsLoadedForTeamId == "team-admin")
  }

  @Test
  func save_returnsFalseWhenFewerThan7Starters() async {
    let host = TeamTestSupport.makeHost()
    var tab = CompositionTestFixtures.fullStarterTab()
    tab.starterAssignments = ["GK": "user-1"]

    let didSave = await host.compositionsViewModel.save(tabs: [tab])

    #expect(didSave == false)
    #expect(host.compositionsViewModel.lastSaveError != nil)
  }

  @Test
  func save_createsCompositionOnSuccess() async {
    let created = TeamComposition(id: "comp-new", name: "Titulaires", teamId: "team-admin")
    let compositionService = MockCompositionService()
    compositionService.createCompositionHandler = { _ in created }
    compositionService.fetchTeamCompositionsHandler = { _ in [created] }
    let host = TeamTestSupport.makeHost(compositionService: compositionService)

    let didSave = await host.compositionsViewModel.save(
      tabs: [CompositionTestFixtures.fullStarterTab()]
    )

    #expect(didSave)
    #expect(host.compositionsViewModel.compositions == [created])
  }

  @Test
  func delete_removesCompositionAndShowsSuccess() async {
    let composition = TeamComposition(id: "comp-1", name: "Titulaires", teamId: "team-admin")
    let compositionService = MockCompositionService()
    compositionService.deleteCompositionHandler = { id in
      #expect(id == composition.id)
    }
    compositionService.fetchTeamCompositionsHandler = { _ in [] }
    let host = TeamTestSupport.makeHost(compositionService: compositionService)

    let didDelete = await host.compositionsViewModel.delete(composition)

    #expect(didDelete)
    #expect(host.toastMessage != nil)
  }

  @Test
  func resetCache_clearsLoadedState() {
    let host = TeamTestSupport.makeHost()
    host.compositionsViewModel.compositions = [
      TeamComposition(id: "comp-1", name: "Titulaires", teamId: "team-admin"),
    ]
    host.compositionsViewModel.compositionsLoadedForTeamId = "team-admin"

    host.compositionsViewModel.resetCache()

    #expect(host.compositionsViewModel.compositions.isEmpty)
    #expect(host.compositionsViewModel.compositionsLoadedForTeamId == nil)
  }
}
