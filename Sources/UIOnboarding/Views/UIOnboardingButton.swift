//
//  UIOnboardingButton.swift
//  UIOnboarding
//
//  Created by Lukman Aščić on 14.02.22.
//

import UIKit

final class UIOnboardingButton: UIButton {
    weak var delegate: UIOnboardingButtonDelegate?

    private let onboardingConfiguration: UIOnboardingButtonConfiguration
    private lazy var impact = UIImpactFeedbackGenerator(style: .light)

    init(withConfiguration configuration: UIOnboardingButtonConfiguration) {
        self.onboardingConfiguration = configuration
        super.init(frame: .zero)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        configuration = makeConfiguration()

        addAction(UIAction { [weak self] _ in self?.impact.prepare() }, for: .touchDown)
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.impact.impactOccurred()
            self.delegate?.didPressContinueButton()
        }, for: .touchUpInside)

        // Replaces traitCollectionDidChange, deprecated in iOS 17.
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            self.setNeedsUpdateConfiguration()
        }

        translatesAutoresizingMaskIntoConstraints = false
        isPointerInteractionEnabled = true
        maximumContentSizeCategory = .accessibilityMedium

        showsLargeContentViewer = true
        largeContentTitle = onboardingConfiguration.title
        addInteraction(UILargeContentViewerInteraction())
    }

    private func makeConfiguration() -> UIButton.Configuration {
        var config = baseConfiguration()

        config.title = onboardingConfiguration.title
        config.titleAlignment = .center
        config.titleLineBreakMode = .byWordWrapping
        config.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)
        config.titleTextAttributesTransformer = .init { [weak self] incoming in
            var outgoing = incoming
            outgoing.font = self?.scaledTitleFont()
            return outgoing
        }

        return config
    }

    private func baseConfiguration() -> UIButton.Configuration {
        // kill your self UIKit lifecycle
        self.titleLabel?.textColor = onboardingConfiguration.titleColor
        
        #if compiler(>=6.2) // Xcode 26 / iOS 26 SDK
        if #available(iOS 26.0, *) {
            var glass: UIButton.Configuration = .prominentGlass()
            glass.baseBackgroundColor = onboardingConfiguration.backgroundColor
            glass.baseForegroundColor = onboardingConfiguration.titleColor
            glass.cornerStyle = .capsule
            return glass
        }
        #endif

        #if targetEnvironment(macCatalyst)
        return .borderedProminent()
        #else
        var filled: UIButton.Configuration = .filled()
        filled.baseBackgroundColor = onboardingConfiguration.backgroundColor
        filled.baseForegroundColor = onboardingConfiguration.titleColor
        filled.cornerStyle = .fixed
        filled.background.cornerRadius = UIScreenType.isiPhoneSE ? 13 : 15
        return filled
        #endif
    }

    private func scaledTitleFont() -> UIFont {
        let size: CGFloat = traitCollection.horizontalSizeClass == .regular ? 19 : 17
        let base = UIFont(name: onboardingConfiguration.fontName, size: size)
            ?? .systemFont(ofSize: size, weight: .bold)
        return UIFontMetrics.default.scaledFont(for: base, compatibleWith: traitCollection)
    }
    
    override func updateConfiguration() {
        configuration = makeConfiguration()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsUpdateConfiguration()
    }
}

protocol UIOnboardingButtonDelegate: AnyObject {
    func didPressContinueButton()
}

extension UIOnboardingButton {
    func configureFont() {
        setNeedsUpdateConfiguration()
    }
}
