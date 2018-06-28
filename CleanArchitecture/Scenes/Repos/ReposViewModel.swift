//
// ReposViewModel.swift
// CleanArchitecture
//
// Created by Tuan Truong on 6/28/18.
// Copyright © 2018 Framgia. All rights reserved.
//

struct ReposViewModel: ViewModelType {
    struct Input {
        let loadTrigger: Driver<Void>
        let reloadTrigger: Driver<Void>
        let loadMoreTrigger: Driver<Void>
        let selectRepoTrigger: Driver<IndexPath>
    }

    struct Output {
        let error: Driver<Error>
        let loading: Driver<Bool>
        let refreshing: Driver<Bool>
        let loadingMore: Driver<Bool>
        let fetchItems: Driver<Void>
        let repoList: Driver<[RepoModel]>
        let selectedRepo: Driver<Void>
        let isEmptyData: Driver<Bool>
    }

    struct RepoModel {
        let repo: Repo
    }

    let navigator: ReposNavigatorType
    let useCase: ReposUseCaseType

    func transform(_ input: Input) -> Output {
        let loadMoreOutput = setupLoadMorePaging(
            loadTrigger: input.loadTrigger,
            getItems: useCase.getRepoList,
            refreshTrigger: input.reloadTrigger,
            refreshItems: useCase.getRepoList,
            loadMoreTrigger: input.loadMoreTrigger,
            loadMoreItems: useCase.loadMoreRepoList)
        let (page, fetchItems, loadError, loading, refreshing, loadingMore) = loadMoreOutput

        let repoList = page
            .map { $0.items.map { RepoModel(repo: $0) } }
            .asDriverOnErrorJustComplete()

        let selectedRepo = input.selectRepoTrigger
            .withLatestFrom(repoList) {
                return ($0, $1)
            }
            .map { indexPath, repoList in
                return repoList[indexPath.row]
            }
            .do(onNext: { repo in
                self.navigator.toRepoDetail(repo: repo.repo)
            })
            .mapToVoid()

        let isEmptyData = Driver.combineLatest(repoList, loading)
            .filter { !$0.1 }
            .map { $0.0.isEmpty }

        return Output(
            error: loadError,
            loading: loading,
            refreshing: refreshing,
            loadingMore: loadingMore,
            fetchItems: fetchItems,
            repoList: repoList,
            selectedRepo: selectedRepo,
            isEmptyData: isEmptyData
        )
    }
}

