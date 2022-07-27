import Image from 'next/image';
import { PropsWithChildren, useState } from 'react';
import { useGameContext } from "./GameProvider";

import cat1 from '../public/cat-body-01.png'
import cat2 from '../public/cat-body-02.png'
import cat3 from '../public/cat-body-03.png'
import cat4 from '../public/cat-body-04.png'
import dog1 from '../public/dog-body-01.png'
import dog2 from '../public/dog-body-02.png'
import dog3 from '../public/dog-body-03.png'
import dog4 from '../public/dog-body-04.png'
import play from '../public/play.png'

type GameContainerProps = {
};

const GameContainer = ({ children }: PropsWithChildren<GameContainerProps>) => {
    const {
        score
    } = useGameContext();

    return (
        <div className="flex flex-col items-center h-screen bg-stone-200">
            <div className="grid grid-flow-row auto-rows-max">
                <div className="flex content-between">
                    <div className="grid grid-flow-col auto-cols-max content-end">
                        <Image alt="Cat 1" src={cat1} width={64} height={64} />
                        <Image alt="Cat 2" src={cat2} width={64} height={64} />
                        <Image alt="Cat 3" src={cat3} width={64} height={64} />
                        <Image alt="Cat 4" src={cat4} width={64} height={64} />
                    </div>
                    <div className="m-auto">
                        <Image alt="Play" src={play} width={100} height={100} />
                        <p className="font-sans text-2xl text-center">Score: {score}</p>
                    </div>
                    <div className="grid grid-flow-col auto-cols-max content-end">
                        <Image alt="Dog 1" src={dog1} width={64} height={64} />
                        <Image alt="Dog 2" src={dog2} width={64} height={64} />
                        <Image alt="Dog 3" src={dog3} width={64} height={64} />
                        <Image alt="Dog 4" src={dog4} width={64} height={64} />
                    </div>
                </div>
                <div className="border-solid border-8 border-black rounded-lg">
                    {children}
                </div>
            </div>
        </div>
    )
};

export default GameContainer;
