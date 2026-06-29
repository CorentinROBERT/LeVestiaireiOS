//
//  MatchDetailCompositionViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchDetailCompositionViewModelTests {
  @Test
  func canEdit_isFalseWhenCompositionLocked() {
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .draft,
      capabilities: ViewModelTestFixtures.manageCompositionCapabilities(),
      isCompositionLocked: true
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    #expect(viewModel.compositionViewModel.canEdit == false)
  }

  @Test
  func canEdit_isTrueWhenManagerAndUnlocked() {
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .draft,
      capabilities: ViewModelTestFixtures.manageCompositionCapabilities()
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    #expect(viewModel.compositionViewModel.canEdit)
  }

  @Test
  func save_returnsFalseWithoutEditRights() async {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .draft)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )
    let tab = CompositionTestFixtures.fullStarterTab()

    let didSave = await viewModel.compositionViewModel.save(tabs: [tab])

    #expect(didSave == false)
  }

  @Test
  func save_returnsFalseWhenFewerThan7Starters() async {
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .upcoming,
      capabilities: ViewModelTestFixtures.manageCompositionCapabilities()
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )
    var tab = CompositionTestFixtures.fullStarterTab()
    tab.starterAssignments = ["GK": "user-1"]

    let didSave = await viewModel.compositionViewModel.save(tabs: [tab])

    #expect(didSave == false)
    #expect(viewModel.errorMessage != nil)
  }

  @Test
  func save_createsCompositionOnSuccess() async {
    let members = CompositionTestFixtures.sevenStarterMembers()
    let matchService = MockMatchDetailService()
    let initial = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .upcoming,
      capabilities: ViewModelTestFixtures.manageCompositionCapabilities()
    )
    let composition = TeamComposition(
      id: "composition-1",
      name: "Titulaires",
      teamId: "team-1"
    )
    let updated = initial.replacingComposition(composition)
    matchService.createMatchCompositionHandler = { _, _ in updated }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: initial,
      matchService: matchService
    )
    viewModel.compositionViewModel.selectablePlayers = CompositionTestFixtures.selectablePlayers(
      from: members
    )

    let didSave = await viewModel.compositionViewModel.save(
      tabs: [CompositionTestFixtures.fullStarterTab(members: members)]
    )

    #expect(didSave)
    #expect(viewModel.match?.composition?.id == "composition-1")
  }

  @Test
  func makeCompositionTabDrafts_reflectsExistingComposition() {
    let composition = TeamPreviewData.compositions.first!
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .upcoming,
      composition: composition
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    let tabs = viewModel.compositionViewModel.makeCompositionTabDrafts()

    #expect(tabs.first?.isMain == true)
    #expect(tabs.first?.starterAssignments.count == 7)
  }

  @Test
  func loadPlayerDirectory_populatesSelectablePlayers() async {
    let players = CompositionTestFixtures.selectablePlayers(
      from: CompositionTestFixtures.sevenStarterMembers()
    )
    let matchService = MockMatchDetailService()
    matchService.fetchSelectablePlayersHandler = { _ in players }
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .upcoming)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    await viewModel.compositionViewModel.loadPlayerDirectory()

    #expect(viewModel.compositionViewModel.selectablePlayers.count == 7)
  }

  @Test
  func setCaptain_succeedsWhenEditable() async {
    let composition = TeamPreviewData.compositions.first!
    let matchService = MockMatchDetailService()
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .upcoming,
      capabilities: ViewModelTestFixtures.manageCompositionCapabilities(),
      composition: composition
    )
    matchService.updateMatchCompositionCaptainHandler = { _, _ in match }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    let didSet = await viewModel.compositionViewModel.setCaptain(captainId: "user-3")

    #expect(didSet)
  }

  @Test
  func lock_succeedsWhenCanManage() async {
    let matchService = MockMatchDetailService()
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .upcoming,
      capabilities: ViewModelTestFixtures.manageCompositionCapabilities(),
      composition: TeamPreviewData.compositions.first
    )
    let locked = ViewModelTestFixtures.copy(match, isCompositionLocked: true)
    matchService.lockMatchCompositionHandler = { _ in locked }
    matchService.fetchMatchHandler = { _, _ in locked }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    let didLock = await viewModel.compositionViewModel.lock()

    #expect(didLock)
    #expect(viewModel.match?.isCompositionLocked == true)
  }

  @Test
  func resetCache_clearsLoadedState() {
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: ViewModelTestFixtures.matchDetail(id: "match-1"),
      matchService: MockMatchDetailService()
    )
    viewModel.compositionViewModel.selectablePlayers = [
      MatchSelectablePlayer(id: "user-1", firstName: "A", lastName: "B"),
    ]
    viewModel.compositionViewModel.teamTemplates = TeamPreviewData.compositions

    viewModel.compositionViewModel.resetCache()

    #expect(viewModel.compositionViewModel.selectablePlayers.isEmpty)
    #expect(viewModel.compositionViewModel.teamTemplates.isEmpty)
  }
}
